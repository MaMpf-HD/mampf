module Rosters
  # Service object to query participants of a Lecture with filtering options.
  # The "registered" view lists users instead of lecture memberships, since
  # people with a running registration need not be on the roster yet; it shows
  # one campaign at a time.
  class ParticipantQuery
    Result = Struct.new(:scope, :total_count, :unassigned_count, :registered_count,
                        :filter_mode, :view, :campaign, keyword_init: true)

    SEARCH_SQL = "#{User::SHOWN_NAME_SQL} ILIKE :q OR users.matriculation_number ILIKE :q".freeze

    def initialize(lecture, params)
      @lecture = lecture
      @params = params
    end

    def call
      filter_mode = @params[:filter] || "all"
      view = @params[:view] == "registered" ? "registered" : "enrolled"
      search = @params[:search].presence

      base_scope =
        @lecture.lecture_memberships
                .joins(:user)
                .includes(user: User::PROGRAM_PRELOAD)
                .merge(User.by_last_name)

      base_scope = base_scope.where(SEARCH_SQL, q: "%#{search}%") if search

      total_count = base_scope.count

      unassigned_scope = build_unassigned_scope(base_scope)
      unassigned_count = unassigned_scope.count

      running = RunningRegistrations.new(@lecture, search: search)
      campaign = running.campaigns.find_by(id: @params[:campaign]) || running.campaigns.first

      scope = case filter_mode
              when "unassigned"
                unassigned_scope
              else
                base_scope
      end
      if view == "registered"
        scope = RunningRegistrations.new(@lecture, search: search, campaign: campaign).users
        scope = scope.none unless campaign
      end

      Result.new(
        scope: scope,
        total_count: total_count,
        unassigned_count: unassigned_count,
        registered_count: running.count,
        filter_mode: filter_mode,
        view: view,
        campaign: campaign
      )
    end

    private

      def build_unassigned_scope(base_scope)
        tutorial_user_ids = TutorialMembership
                            .joins(:tutorial)
                            .where(tutorials: { lecture_id: @lecture.id })
                            .select(:user_id)

        talk_user_ids = SpeakerTalkJoin
                        .joins(:talk)
                        .where(talks: { lecture_id: @lecture.id })
                        .select(:speaker_id)

        cohort_user_ids = CohortMembership
                          .joins(:cohort)
                          .where(cohorts: {
                                   context_id: @lecture.id,
                                   context_type: "Lecture",
                                   propagate_to_lecture: true
                                 })
                          .select(:user_id)

        base_scope
          .where.not(user_id: tutorial_user_ids)
          .where.not(user_id: talk_user_ids)
          .where.not(user_id: cohort_user_ids)
      end
  end
end
