module UserRegistrations
  class PreferencesHandler
    MAX_PREFERENCES = 3

    # struct for store temporary preference items during modification process,
    # will be used in form
    SimpleItemPreference = Struct.new(:id, :rank)

    # struct for render preference items in FE
    ItemPreference       = Struct.new(:item, :rank)

    def pref_items_from_ranked_params(preferences)
      preferences.to_h.filter_map do |rank, item_id|
        next if item_id.blank?

        SimpleItemPreference.new(item_id, rank.to_i)
      end.sort_by(&:rank)
    end

    # preferences info saved in DB
    def preferences_info(campaign, user)
      campaign.user_registrations
              .where(user_id: user.id, status: [:confirmed, :pending])
              .includes(:registration_item)
              .sort_by { |registration| preference_sort_key(registration.preference_rank) }
              .map do |registration|
        ItemPreference.new(registration.registration_item, registration.preference_rank)
      end
    end

    private

      def preference_sort_key(rank)
        [rank.nil? ? 1 : 0, rank || 0]
      end
  end
end
