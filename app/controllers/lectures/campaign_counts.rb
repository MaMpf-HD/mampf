module Lectures
  # Counts the people in each campaign of a lecture for the lecturer's block:
  # those registered or with preferences while it runs, those on the rosters
  # of its groups once it is finalized. A person in two of its groups, as a
  # cohort allows, counts once. The rosters are read with one query per kind
  # of group, not one per group.
  class CampaignCounts
    def initialize(campaigns)
      @campaigns = campaigns
    end

    def to_h
      @campaigns.to_h do |campaign|
        count = if campaign.completed?
          campaign.registration_items.flat_map do |item|
            roster_user_ids.fetch([item.registerable_type, item.registerable_id], [])
          end.uniq.size
        else
          registered.fetch(campaign.id, 0)
        end
        [campaign.id, count]
      end
    end

    private

      def registered
        @registered ||= Registration::UserRegistration
                        .where(registration_campaign_id: @campaigns.map(&:id))
                        .where.not(status: :rejected)
                        .group(:registration_campaign_id)
                        .distinct.count(:user_id)
      end

      def roster_user_ids
        @roster_user_ids ||= finalized_registerables.group_by(&:class)
                                                    .each_with_object({}) do |(klass, group), ids|
          rosters_of(group).each do |owner_id, user_id|
            (ids[[klass.name, owner_id]] ||= []) << user_id
          end
        end
      end

      def finalized_registerables
        @campaigns.select(&:completed?)
                  .flat_map { |campaign| campaign.registration_items.map(&:registerable) }
      end

      # The roster association with its own scope, so an exam counts only its
      # active entries, as `Exam#roster_entries` does.
      def rosters_of(group)
        sample = group.first
        reflection = sample.association(sample.roster_association_name).reflection
        scope = reflection.klass.where(reflection.foreign_key => group.map(&:id))
        scope = scope.instance_exec(&reflection.scope) if reflection.scope
        scope.pluck(reflection.foreign_key, sample.roster_user_id_column)
      end
  end
end
