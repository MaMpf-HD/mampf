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
      rosterables =
        lecture.tutorials
               .includes(:tutors, :members)
               .where(id: TutorialMembership.where(user_id: @user.id).select(:tutorial_id))
               .to_a +
        lecture.cohorts
               .includes(:members)
               .where(id: CohortMembership.where(user_id: @user.id).select(:cohort_id))
               .to_a +
        lecture.talks
               .includes(:speakers, :members)
               .where(id: SpeakerTalkJoin.where(speaker_id: @user.id).select(:talk_id))
               .to_a

      rosterables.presence
    end
  end
end
