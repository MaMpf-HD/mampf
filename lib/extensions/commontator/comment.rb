module Extensions
  module Commontator
    module Comment
      extend ActiveSupport::Concern

      included do
        validates :body, presence: true
        validates :body, uniqueness: {
          scope: [
            :creator_type, :creator_id, :thread_id, :parent_id, :deleted_at
          ],
          message: :double_posted
        }

        has_one :annotation, foreign_key: :public_comment_id

        def medium
          thread.commontable
        end
      end
    end
  end
end
