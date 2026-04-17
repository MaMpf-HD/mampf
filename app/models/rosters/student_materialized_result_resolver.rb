module Rosters
  # get roster results for student
  class StudentMaterializedResultResolver
    def initialize(user)
      @user = user
    end

    def succeed_items(campaign)
      registerables = campaign.registration_items.map(&:registerable).uniq

      succeed_items = []
      registerables.each do |registerable|
        memberships = registerable.roster_entries
                                  .where(source_campaign_id: campaign.id,
                                         registerable.roster_user_id_column => @user.id)
        next unless memberships.any?

        succeed_items.concat(Registration::Item.where(
                               registerable_type: registerable.class.name,
                               registerable_id: registerable&.id,
                               registration_campaign_id: campaign.id
                             ))
      end
      succeed_items
    end

    def all_rosterized_for_lecture(lecture)
      names =
        lecture.tutorials
               .joins(:tutorial_memberships)
               .where(tutorial_memberships: { user_id: @user.id })
               .map { |tutorial| rosterable_label(tutorial) } +
        lecture.cohorts
               .joins(:cohort_memberships)
               .where(cohort_memberships: { user_id: @user.id })
               .map { |cohort| rosterable_label(cohort) } +
        lecture.talks
               .joins(:speaker_talk_joins)
               .where(speaker_talk_joins: { speaker_id: @user.id })
               .map { |talk| rosterable_label(talk) }

      names.presence&.join(", ")
    end

    private

      def rosterable_label(rosterable)
        "#{rosterable.class.model_name.human} #{rosterable.title}"
      end
  end
end
