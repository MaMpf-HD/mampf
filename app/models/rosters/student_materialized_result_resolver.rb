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
      tutorials = lecture.tutorials.includes(:tutorial_memberships)
                         .where(tutorial_memberships: { user_id: @user.id })
      cohorts = lecture.cohorts.includes(:cohort_memberships)
                       .where(cohort_memberships: { user_id: @user.id })
      talks = lecture.talks.includes(:speaker_talk_joins)
                     .where(speaker_talk_joins: { speaker_id: @user.id })
      registerables = tutorials + cohorts + talks
      name = []
      if registerables.any?
        registerables.each do |registerable|
          name << (registerable.class.name.humanize + " " + registerable.title)
        end
      end
      name.any? ? name.join(", ") : nil
    end
  end
end
