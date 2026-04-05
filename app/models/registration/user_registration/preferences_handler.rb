module Registration
  class UserRegistration
    # Handler for managing user preferences in preference-based registration campaigns,
    # including parsing preference data from the frontend and preparing preference data for display.
    class PreferencesHandler
      # struct for store temporary preference items during modification process,
      # will be used in form
      SimpleItemPreference = Struct.new(:id, :rank)

      # struct for render preference items in FE
      ItemPreference       = Struct.new(:item, :rank)

      # parse json from FE
      def pref_item_from_json(json)
        Array(JSON.parse(json)).map do |h|
          SimpleItemPreference.new(
            h.dig("item", "id"),
            h["rank"].to_i
          )
        end
      end

      def pref_item_build_for_save(json)
        normalize_ranks(pref_item_from_json(json))
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

      def up(item_id, json)
        pref_items = pref_item_from_json(json)
        swap(pref_items, item_id, -1)
        build_preferences(pref_items)
      end

      def down(item_id, json)
        pref_items = pref_item_from_json(json)
        swap(pref_items, item_id, +1)
        build_preferences(pref_items)
      end

      def add(item_id, json)
        pref_items = pref_item_from_json(json)
        unless pref_items.any? { |i| i.id == item_id }
          pref_items << SimpleItemPreference.new(item_id, pref_items.size + 1)
        end
        build_preferences(pref_items)
      end

      def remove(item_id, json)
        pref_items = pref_item_from_json(json)
        remaining  = pref_items.reject { |i| i.id == item_id }
        normalize_ranks(remaining)
        build_preferences(remaining)
      end

      private

        def swap(pref_items, item_id, delta)
          item = pref_items.find { |i| i.id == item_id }
          return unless item

          target_rank = item.rank + delta
          other = pref_items.find { |i| i.rank == target_rank }
          return unless other

          item.rank, other.rank = other.rank, item.rank
        end

        # ensure ranks are continuous from 1 to n without duplication
        def normalize_ranks(pref_items)
          pref_items.sort_by!(&:rank)
          pref_items.each_with_index { |i, idx| i.rank = idx + 1 }
          pref_items
        end

        # build preference info based on given info
        def build_preferences(pref_items)
          normalize_ranks(pref_items)
          items = Registration::Item.where(id: pref_items.map(&:id)).index_by(&:id)

          pref_items.map do |pref|
            ItemPreference.new(items[pref.id], pref.rank)
          end
        end
    end
  end
end
