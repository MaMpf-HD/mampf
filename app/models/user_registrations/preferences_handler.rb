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
      user_registrations = campaign.user_registrations
                                   .where(user_id: user.id)
                                   .where(status: [:confirmed, :pending])
      user_registrations.includes(:registration_item)
                        .map(&:registration_item)
                        .flatten
                        .sort_by { |i| i.preference_rank(user) }
                        .map do |item|
        ItemPreference.new(item,
                           item.preference_rank(user))
      end
    end
  end
end
