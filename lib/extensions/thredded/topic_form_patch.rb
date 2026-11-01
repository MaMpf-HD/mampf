module Extensions
  module Thredded
    # Patches two cases in which Thredded::TopicForm raises instead of saving
    # a new forum topic or showing its validation errors.
    module TopicFormPatch
      # Creates the user's Thredded::UserDetail up front. Otherwise, on a user's
      # first topic, the topic and its post each build an unsaved one, and the
      # post's counter cache raises on it under Rails 8.1.
      def save
        ensure_user_detail if non_null_user
        super
      end

      private

        # Thredded's activity job creates the same detail when a forum page is
        # opened; if it does so between the lookup and the insert, its detail
        # stands. Any other invalid detail still raises.
        def ensure_user_detail
          ::Thredded::UserDetail.find_or_create_by!(user: non_null_user)
        rescue ActiveRecord::RecordNotUnique
          ::Thredded::UserDetail.find_by!(user: non_null_user)
        rescue ActiveRecord::RecordInvalid => e
          raise unless e.record.errors.of_kind?(:user_id, :taken)

          ::Thredded::UserDetail.find_by!(user: non_null_user)
        end

        # Copies the errors of the topic and its post onto the form. Thredded's
        # own version reads them as [attribute, message] pairs and raises.
        def promote_errors(child_errors)
          child_errors.each { |error| errors.add(error.attribute, error.message) }
        end
    end
  end
end
