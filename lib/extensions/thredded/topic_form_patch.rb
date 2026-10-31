module Extensions
  module Thredded
    # Patches two cases in which Thredded::TopicForm raises instead of saving
    # a new forum topic or showing its validation errors.
    module TopicFormPatch
      # Creates the user's Thredded::UserDetail up front. Otherwise, on a user's
      # first topic, the topic and its post each build an unsaved one, and the
      # post's counter cache raises on it under Rails 8.1.
      def save
        ::Thredded::UserDetail.find_or_create_by!(user: non_null_user) if non_null_user
        super
      end

      private

        # Copies the errors of the topic and its post onto the form. Thredded's
        # own version reads them as [attribute, message] pairs and raises.
        def promote_errors(child_errors)
          child_errors.each { |error| errors.add(error.attribute, error.message) }
        end
    end
  end
end
