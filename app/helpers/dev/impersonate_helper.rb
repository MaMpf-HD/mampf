module Dev
  module ImpersonateHelper
    def all_users_for_impersonation
      @all_users_for_impersonation ||= Rails.cache.fetch(
        all_users_for_impersonation_cache_key,
        expires_in: 5.minutes
      ) do
        users = User.order(:email).pluck(:id, :email)
                    .map { |id, email| [id, email.split("@").first] }

        users.sort_by do |_, name|
          [sort_priority(name), name.downcase]
        end
      end
    end

    private

      def all_users_for_impersonation_cache_key
        [
          "dev/impersonate_dropdown/all_users",
          User.maximum(:updated_at)&.utc&.to_i
        ]
      end

      def sort_priority(name)
        lowered_name = name.downcase
        return 0 if lowered_name.start_with?("student")
        return 1 if lowered_name.start_with?("tutor", "teacher")
        return 2 if lowered_name.start_with?("admin")

        3
      end
  end
end
