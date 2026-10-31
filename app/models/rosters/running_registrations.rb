module Rosters
  # Registrations of a lecture's open, closed and processing campaigns, whose
  # people reach their groups only with Registration::Campaign#finalize!.
  # Exam campaigns are left out: they fill exam rosters, not the lecture's.
  class RunningRegistrations
    Entry = Struct.new(:campaign, :registrations, keyword_init: true) do
      # Leaves out a forced assignment, which the person never chose.
      def chosen_items
        registrations.select { |r| campaign.first_come_first_served? || r.preference_rank }
                     .sort_by { |r| r.preference_rank.to_i }
                     .map(&:registration_item)
      end

      # The item a preference allocation gave the person; nil before the
      # allocation is computed and for someone it left without a place.
      def allocated_item
        return unless allocated?

        registrations.find(&:confirmed?)&.registration_item
      end

      def allocated?
        campaign.preference_based? && campaign.last_allocation_calculated_at.present?
      end
    end

    # campaign: one of #campaigns, which the caller checks; nil means all of them.
    def initialize(lecture, search: nil, campaign: nil)
      @lecture = lecture
      @search = search.presence
      @campaign = campaign
    end

    def campaigns
      Registration::Campaign.running.where(campaignable: @lecture).non_exam
                            .order(:registration_deadline, :created_at, :id)
    end

    # Everyone, regardless of the search and unsorted: the program statistics
    # count all of them and group the relation.
    def people
      User.where(id: registrations.select(:user_id))
    end

    def users
      scope = people.by_last_name
      return scope unless @search

      scope.shown_name_or_matriculation_number_like(@search)
    end

    delegate :count, to: :users

    # Returns { campaign_id => people the search finds }, counting people rather
    # than registrations: a preference campaign holds one per choice.
    def counts_by_campaign
      registrations.where(user_id: users.select(:id))
                   .group(:registration_campaign_id)
                   .distinct
                   .count(:user_id)
    end

    # Returns { user_id => Entry } in the given campaign.
    def entry_by_user(user_ids)
      raise(ArgumentError, "entry_by_user needs a campaign") unless @campaign

      regs = registrations.where(user_id: user_ids)
                          .includes(registration_item: :registerable).to_a
      preload_titles(regs.map { |r| r.registration_item.registerable })
      regs.group_by(&:user_id).transform_values do |user_regs|
        Entry.new(campaign: @campaign, registrations: user_regs)
      end
    end

    private

      def registrations
        Registration::UserRegistration
          .where(status: [:pending, :confirmed])
          .where(registration_campaign_id: @campaign&.id || campaigns.select(:id))
      end

      # Tutorial and talk titles name their tutors and speakers.
      def preload_titles(registerables)
        { Tutorial => :tutors, Talk => :speakers }.each do |klass, association|
          records = registerables.grep(klass).uniq
          ActiveRecord::Associations::Preloader.new(records: records,
                                                    associations: association).call
        end
      end
  end
end
