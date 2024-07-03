module Extensions
  module Commontator
    module Comment
      extend ActiveSupport::Concern

      included do
        has_one :annotation, foreign_key: :public_comment_id

        def medium
          thread.commontable
        end
      end
    end
  end
end
