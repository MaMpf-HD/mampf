module Rosters
  class ParticipantQuery
    Result = Struct.new(:scope, :total_count, :unassigned_count, :filter_mode, keyword_init: true)

    def initialize(lecture, params)
      @lecture = lecture
      @params = params
    end

    def call
      filter_mode = @params[:filter] || "all"

      base_scope = @lecture.lecture_memberships
                           .joins(:user)
                           .includes(:user)
                           .order(Arel.sql("COALESCE(NULLIF(users.name_in_tutorials, ''), users.name) ASC"))

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
        # Users in tutorial memberships for this lecture
        tutorial_user_ids = TutorialMembership.joins(:tutorial)
                                              .where(tutorials: { lecture_id: @lecture.id })
                                              .select(:user_id)

        # Users in talk memberships for this lecture
        talk_user_ids = SpeakerTalkJoin.joins(:talk)
                                       .where(talks: { lecture_id: @lecture.id })
                                       .select(:speaker_id)

        # Rails 7+ allows .union but can be finicky with different table structures / primary keys
        # We manually construct the SQL to be safe regardless of the primary key differences
        assigned_ids_sql = "(#{tutorial_user_ids.to_sql}) UNION (#{talk_user_ids.to_sql})"

        base_scope.where.not(user_id: Arel.sql(assigned_ids_sql))
      end
  end
end
