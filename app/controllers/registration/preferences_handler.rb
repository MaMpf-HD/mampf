module Registration
  class UserRegistrations
    class PreferencesHandler
      PreferenceItem = Struct.new(:id, :preference_rank)

      def up(item_id)
        item = Registration::Item.find(item_id)
        pref_item = session[:preferences].map do |item_hash|
          PreferenceItem.new(item_hash["id"], item_hash["preference_rank"])
        end

        temp_item = pref_item.find { |i| i.id == item_id }
        temp_item_above = pref_item.find { |i| i.preference_rank == temp_item.preference_rank - 1 }
        if temp_item && temp_item_above
          temp_item.preference_rank -= 1
          temp_item_above.preference_rank += 1
        end
        data = pref_item.map { |i| i.to_h.stringify_keys }
        session[:preferences] = data
        compute_preferences_from_session
        @campaign = item.registration_campaign

        render partial: "registration/main/preferences_table",
               locals: { item_preferences: @item_preferences, campaign: @campaign }
      end

      def down(item_id)
        item = Registration::Item.find(item_id)
        pref_item = session[:preferences].map do |item_hash|
          PreferenceItem.new(item_hash["id"], item_hash["preference_rank"])
        end
        temp_item = pref_item.find { |i| i.id == item_id }
        temp_item_below = pref_item.find { |i| i.preference_rank == temp_item.preference_rank + 1 }
        if temp_item && temp_item_below
          temp_item.preference_rank += 1
          temp_item_below.preference_rank -= 1
        end
        data = pref_item.map { |i| i.to_h.stringify_keys }
        session[:preferences] = data
        compute_preferences_from_session
        @campaign = item.registration_campaign

        render partial: "registration/main/preferences_table",
               locals: { item_preferences: @item_preferences, campaign: @campaign }
      end

      def add(item_id)
        item = Registration::Item.find(item_id)
        preferences = session[:preferences] || []
        unless preferences.any? { |i| i["id"].to_i == item_id.to_i }
          preferences << { "id" => item_id.to_i, "preference_rank" => preferences.size + 1 }
        end
        session[:preferences] = preferences
        compute_preferences_from_session
        @campaign = item.registration_campaign

        render partial: "registration/main/preferences_table",
               locals: { item_preferences: @item_preferences, campaign: @campaign }
      end

      def compute_preferences_from_session
        preferences_hash = session[:preferences]
        t = 0
        preferences = preferences_hash.sort_by { |h| h["preference_rank"] }
                                      .map { |item_hash| Registration::Item.find(item_hash["id"].to_i) }
        @item_preferences = preferences.filter { |item| item.nil? == false }
      end

      def reset_preferences
        session[:preferences] = []

        # update by turbo frame
      end
    end
  end
end
