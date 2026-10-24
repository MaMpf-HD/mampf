module Rosters
  # Service object to query participants of a Lecture with filtering options.
  # The "registered" view lists users instead of lecture memberships, since
  # people with a running registration need not be on the roster yet; it shows
  # one campaign at a time. The "left" view lists the excluded memberships of
  # those who have left the roster or been removed from it.
  class ParticipantQuery
    VIEWS = ["enrolled", "registered", "left"].freeze

    Result = Struct.new(:scope, :total_count, :registered_count, :left_count, :view,
                        :campaign, keyword_init: true)

    SEARCH_SQL = "#{User::SHOWN_NAME_SQL} ILIKE :q OR users.matriculation_number ILIKE :q".freeze

    def initialize(lecture, params)
      @lecture = lecture
      @params = params
    end

    def call
      view = VIEWS.include?(@params[:view]) ? @params[:view] : "enrolled"
      search = @params[:search].presence

      base_scope =
        @lecture.lecture_memberships
                .joins(:user)
                .includes(user: User::PROGRAM_PRELOAD)
                .merge(User.by_last_name)

      base_scope = base_scope.where(SEARCH_SQL, q: "%#{search}%") if search

      total_count = base_scope.count

      running = RunningRegistrations.new(@lecture, search: search)
      campaign = running.campaigns.find_by(id: @params[:campaign]) || running.campaigns.first

      scope = base_scope
      if view == "registered"
        scope = RunningRegistrations.new(@lecture, search: search, campaign: campaign).users
        scope = scope.none unless campaign
      end
      left = left_scope(search)
      scope = left if view == "left"

      Result.new(
        scope: scope,
        total_count: total_count,
        registered_count: running.count,
        left_count: left.count,
        view: view,
        campaign: campaign
      )
    end

    private

      def left_scope(search)
        scope = @lecture.excluded_lecture_memberships
                        .joins(:user)
                        .includes(:excluded_by, user: User::PROGRAM_PRELOAD)
                        .merge(User.by_last_name)
        search ? scope.where(SEARCH_SQL, q: "%#{search}%") : scope
      end
  end
end
