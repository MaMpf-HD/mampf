module Registration
  class UserRegistration
    class PreferencesHandler
      SimpleItemPreference = Struct.new(:id, :rank)
      ItemPreference       = Struct.new(:item, :rank)

      def pref_item_from_json(json)
        data = JSON.parse(json)

        Array(data).map do |h|
          item_id = h.dig("item", "id")
          rank    = h["rank"]

          unless item_id.is_a?(Integer) || item_id.to_s.match?(/\A\d+\z/)
            raise(ArgumentError, "Invalid or missing item.id in preference payload: #{h.inspect}")
          end

          unless rank.is_a?(Integer) || rank.to_s.match?(/\A\d+\z/)
            raise(ArgumentError, "Invalid or missing rank in preference payload: #{h.inspect}")
          end

          SimpleItemPreference.new(item_id.to_i, rank.to_i)
        end
      end

      def pref_item_build_for_save(json)
        normalize_ranks(pref_item_from_json(json))
      end

      def preferences_info(campaign, user)
        user_registrations = campaign.user_registrations
                                     .where(user_id: user.id)
                                     .where(status: [:confirmed, :pending])
        user_registrations.includes(:registration_item)
                          .flat_map(&:registration_item)
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

        def normalize_ranks(pref_items)
          pref_items.sort_by!(&:rank)
          pref_items.each_with_index { |i, idx| i.rank = idx + 1 }
          pref_items
        end

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
