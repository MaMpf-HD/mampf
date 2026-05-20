module Extensions
  module Commontator
    # Commontator rejects repeated comment bodies by the same author within one
    # thread, which blocks legitimate replies like repeated acknowledgements on
    # the same medium. We keep this patch so those normal interactions remain
    # possible while still preserving a narrower guard against accidental
    # double posts.
    module CommentPatch
      module_function

      ORIGINAL_UNIQUENESS_SCOPE = [
        :creator_type, :creator_id, :thread_id, :deleted_at
      ].freeze
      CUSTOM_UNIQUENESS_SCOPE = [
        :creator_type, :creator_id, :thread_id, :parent_id, :deleted_at
      ].freeze

      def apply!
        return unless ActiveRecord::Base.connection.table_exists?(:thredded_topics)

        validators.each do |validator|
          ::Commontator::Comment._validators[:body].delete(validator)
          ::Commontator::Comment.skip_callback(
            :validate,
            :before,
            validator,
            raise: false
          )
        end

        ::Commontator::Comment.validates(:body, presence: true)
        ::Commontator::Comment.validates(:body, uniqueness: {
                                           scope: CUSTOM_UNIQUENESS_SCOPE,
                                           message: :double_posted
                                         })

        unless ::Commontator::Comment.reflect_on_association(:annotation)
          ::Commontator::Comment.has_one(
            :annotation,
            foreign_key: :public_comment_id
          )
        end

        ::Commontator::Comment.class_eval do
          def medium
            thread.commontable
          end
        end
      end

      def validators
        ::Commontator::Comment._validators[:body].select do |candidate|
          candidate.attributes == [:body] &&
            (
              candidate.is_a?(ActiveModel::Validations::PresenceValidator) ||
              removable_uniqueness_validator?(candidate)
            )
        end
      end

      def removable_uniqueness_validator?(candidate)
        return false unless candidate.is_a?(ActiveRecord::Validations::UniquenessValidator)

        [ORIGINAL_UNIQUENESS_SCOPE, CUSTOM_UNIQUENESS_SCOPE].include?(candidate.options[:scope])
      end
    end
  end
end
