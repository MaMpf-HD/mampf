module Rosters
  # Service object to query participants of a Lecture with filtering options.
  class ParticipantQuery
    Result = Struct.new(:scope, :total_count, :unassigned_count, :filter_mode, keyword_init: true)

    def initialize(lecture, params)
      @lecture = lecture
      @params = params
    end

    def call
      filter_mode = @params[:filter] || "all"
      search = @params[:search].presence

      base_scope =
        @lecture.lecture_memberships
                .joins(:user)
                .includes(:user)
                .order(Arel.sql("COALESCE(NULLIF(users.name_in_tutorials, ''), users.name) ASC"))

      if search
        base_scope = base_scope.where(
          "users.name ILIKE :q OR users.email ILIKE :q OR users.name_in_tutorials ILIKE :q",
          q: "%#{search}%"
        )
      end

      total_count = base_scope.count

      unassigned_scope = build_unassigned_scope(base_scope)
      unassigned_count = unassigned_scope.count

      scope = case filter_mode
              when "unassigned"
                unassigned_scope
              else
                base_scope
      end

      Result.new(
        scope: scope,
        total_count: total_count,
        unassigned_count: unassigned_count,
        filter_mode: filter_mode
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
