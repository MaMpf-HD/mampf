module Registration
  class UserRegistrations
    class PreferencesHandler
      PreferenceItem = Struct.new(:id, :preference_rank)
      TempItemPreference = Struct.new(:item, :temp_preference_rank)

      def pref_item_from_json(preferences_json)
        preferences_store = JSON.parse(preferences_json) || []
        preferences_store.map do |item_hash|
          PreferenceItem.new(item_hash["item"]["id"].to_i, item_hash["temp_preference_rank"].to_i)
        end
      end

      def up(item_id, preferences_json)
        pref_item = pref_item_from_json(preferences_json)
        temp_item = pref_item.find { |i| i.id == item_id }
        temp_item_above = pref_item.find { |i| i.preference_rank == temp_item.preference_rank - 1 }
        if temp_item && temp_item_above
          temp_item.preference_rank -= 1
          temp_item_above.preference_rank += 1
        end
        compute_preferences_from_preferences_store(pref_item)
      end

      def down(item_id, preferences_json)
        pref_item = pref_item_from_json(preferences_json)
        temp_item = pref_item.find { |i| i.id == item_id }
        temp_item_below = pref_item.find { |i| i.preference_rank == temp_item.preference_rank + 1 }
        if temp_item && temp_item_below
          temp_item.preference_rank += 1
          temp_item_below.preference_rank -= 1
        end
        compute_preferences_from_preferences_store(pref_item)
      end

      def add(item_id, preferences_json)
        pref_item = pref_item_from_json(preferences_json)
        unless pref_item.any? { |i| i.id == item_id }
          pref_item << PreferenceItem.new(item_id, pref_item.size + 1)
        end
        compute_preferences_from_preferences_store(pref_item)
      end

      def compute_preferences_from_preferences_store(pref_item)
        preferences_store = pref_item.map { |i| i.to_h.stringify_keys }
        preferences_store_sorted = preferences_store.sort_by { |h| h["preference_rank"] }
        preferences_store_sorted.map do |item_hash|
          item = Registration::Item.find(item_hash["id"].to_i)
          TempItemPreference.new(item, item_hash["preference_rank"])
        end
      end
    end
  end
end
