module Registration
  class UserRegistration
    class PreferencesHandler
      MAX_PREFERENCES = 3

      # struct for store temporary preference items during modification process,
      # will be used in form
      SimpleItemPreference = Struct.new(:id, :rank)

      # struct for render preference items in FE
      ItemPreference       = Struct.new(:item, :rank)

      def pref_item_build_with_rank(campaign, user, item_id, rank)
        pref_items = preferences_info(campaign, user).map do |pref|
          SimpleItemPreference.new(pref.item.id, pref.rank)
        end
        set_pref_item_rank(pref_items, item_id, rank)
        pref_items
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

      private

        def set_pref_item_rank(pref_items, item_id, rank)
          item_id = item_id.to_s
          target_rank = persistent_target_rank(rank)
          used_ranks = [target_rank]
          remaining = pref_items.reject { |i| i.id == item_id }
          updated = [SimpleItemPreference.new(item_id, target_rank)]

          remaining.sort_by(&:rank).each do |pref|
            pref.rank = next_available_rank(used_ranks) if used_ranks.include?(pref.rank) ||
                                                           pref.rank > MAX_PREFERENCES
            next unless pref.rank

            used_ranks << pref.rank
            updated << pref
          end

          pref_items.replace(updated.sort_by(&:rank))
        end

        def persistent_target_rank(rank)
          rank.to_i.clamp(1, MAX_PREFERENCES)
        end

        def next_available_rank(used_ranks)
          (1..MAX_PREFERENCES).detect { |rank| used_ranks.exclude?(rank) }
        end
    end
  end
end
