module Extensions
  module Commontator
    module Comment
      extend ActiveSupport::Concern

      included do
        has_one :annotation, foreign_key: :public_comment_id
        after_update :update_annotation

        def medium
          thread.commontable
        end
      end

      def update_annotation
        pp 'we can do something here'
      end
    end
  end
end