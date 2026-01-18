module Extensions
  module Commontator
    module Comment
      extend ActiveSupport::Concern

      included do
        has_one :annotation, foreign_key: :public_comment_id

        after_create :increment_user_streak

        def medium
          thread.commontable
        end

        private

          def increment_user_streak
            creator.increment_streak if creator.is_a?(User)
          end
      end
    end
  end
end
