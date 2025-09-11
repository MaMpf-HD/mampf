module SearchForm
  module Fields
    module Mixins
      # A lightweight mixin module providing common functionality for form field components.
      # This module eliminates repetitive code across field classes without introducing
      # complex inheritance hierarchies or Rails concerns.
      #
      # The module provides:
      # - Standard field initialization patterns
      # - Common delegation setup via included hook
      # - Form state management interface
      # - Content block support
      # - Validation hooks
      #
      # @example Including in a field class
      #   class TextField < ViewComponent::Base
      #     include PrimitiveFieldMixin
      #
      #     def initialize(name:, label:, form_state:, **options)
      #       super()
      #       initialize_field_data(name: name, label: label, form_state: form_state,
      #                            default_classes: ["form-control"], **options)
      #     end
      #   end
      module PrimitiveFieldMixin
        # Rails hook that runs when the module is included.
        # Automatically sets up the common delegations for the including class.
        #
        # @param base [Class] The class that included this module
        # @return [void]
        def self.included(base)
          super
          base.delegate(:name, :label, :help_text, :form, :container_class, :show_help_text?,
                        :show_content?, :content, :options, to: :field_data)
          base.delegate(:form_state, to: :field_data)
        end

        # Initializes the FieldData object with standard configuration.
        # This method handles the common pattern of creating a FieldData instance
        # and setting up default CSS classes for the field type.
        #
        # @param name [Symbol] The field name used for form binding and ID generation
        # @param label [String] The human-readable label for the field
        # @param form_state [FormState] The form state object for context and ID generation
        # @param default_classes [Array<String>] CSS classes specific to this field type
        # @param options [Hash] Additional options passed through to FieldData
        # @return [void]
        def initialize_field_data(name:, label:, form_state:, default_classes: [], **options)
          @field_data = FieldData.new(
            name: name,
            label: label,
            help_text: options[:help_text],
            form_state: form_state,
            options: options.dup
          )

          # Set field-type-specific default CSS classes
          field_data.define_singleton_method(:default_field_classes) { default_classes }
          field_data.extract_and_update_field_classes!(options)
        end

        # Sets the form state for this field component.
        # This is part of the SearchForm's auto-injection interface.
        #
        # @param new_form_state [FormState] The new form state to assign
        # @return [void]
        delegate :form_state=, to: :field_data

        # Associates this field with a form builder and returns self for method chaining.
        # This is used by the SearchForm system to inject form context.
        #
        # @param form [ActionView::Helpers::FormBuilder] The Rails form builder
        # @return [self] Returns self to allow method chaining
        def with_form(form)
          field_data.form_state.with_form(form)
          self
        end

        # Associates a content block with this field and returns self for method chaining.
        # Content blocks are typically used for additional field content like help text,
        # buttons, or nested field groups.
        #
        # @param block [Proc] The content block to associate with this field
        # @return [self] Returns self to allow method chaining
        def with_content(&)
          field_data.with_content(&)
          self
        end

        # ViewComponent lifecycle hook that validates the field is properly configured.
        # This ensures that the form builder has been set before attempting to render,
        # preventing runtime errors from missing form context.
        #
        # @raise [RuntimeError] If no form builder has been set
        # @return [void]
        def before_render
          raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
        end
      end
    end
  end
end
