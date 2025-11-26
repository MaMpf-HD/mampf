module SearchForm
  module Fields
    module Mixins
      # Very lightweight mixin for common field setup patterns in composite fields.
      # This mixin provides factory methods for creating primitive field components
      # with consistent configuration and automatic form integration.
      #
      # Composite fields that include this mixin should implement a `setup_fields`
      # method that uses the provided `create_*` helpers to build their components.
      #
      # @example Basic usage from CourseField
      #   class CourseField < ViewComponent::Base
      #     include Mixins::CompositeFieldMixin
      #
      #     private
      #
      #       def setup_fields
      #         @multi_select_field = create_multi_select_field(
      #           name: :course_ids,
      #           label: I18n.t("basics.courses"),
      #           collection: Course.order(:title).pluck(:title, :id)
      #         )
      #         @all_checkbox = create_all_checkbox(for_field_name: :course_ids)
      #       end
      #   end
      module CompositeFieldMixin
        def self.included(base)
          base.attr_accessor(:form_state)
          base.delegate(:form, to: :form_state)
        end

        def with_form(form)
          form_state.with_form(form)
          self
        end

        def before_render
          setup_fields
        end

        protected

          # Creates a multi-select field with standard configuration.
          # This is the most commonly used method for building composite fields
          # that allow multiple selections from a collection.
          #
          # @param name [Symbol] The field name for form binding
          # @param label [String] The human-readable label
          # @param collection [Array] Array of [text, value] pairs for options
          # @param config [Hash] Additional options passed to the field
          # @return [Fields::Primitives::MultiSelectField] Configured multi-select field
          #
          # @example From TeacherField
          #   create_multi_select_field(
          #     name: :teacher_ids,
          #     label: I18n.t("basics.teachers"),
          #     collection: User.select_teachers,
          #     help_text: I18n.t("search.filters.helpdesks.teacher_filter")
          #   )
          #
          # @example From TagField with AJAX
          #   create_multi_select_field(
          #     name: :tag_ids,
          #     label: I18n.t("basics.tags"),
          #     collection: [],
          #     data: { ajax: true, model: "tag", locale: I18n.locale }
          #   )
          def create_multi_select_field(**config)
            Fields::Primitives::MultiSelectField.new(
              form_state: form_state,
              **config
            ).with_form(form)
          end

          # Creates an "All" toggle checkbox that typically controls a multi-select field.
          # Automatically generates the checkbox name and sets up default styling and behavior.
          #
          # @param for_field_name [Symbol] The name of the field this checkbox controls
          #   (e.g., :course_ids becomes "all_courses")
          # @param extra_config [Hash] Additional configuration to override defaults
          # @return [Fields::Primitives::CheckboxField] Configured "All" checkbox
          #
          # @example From CourseField (simple toggle)
          #   create_all_checkbox(for_field_name: :course_ids)
          #
          # @example From TagField (with radio group control)
          #   create_all_checkbox(
          #     for_field_name: :tag_ids,
          #     stimulus: {
          #       toggle: true,
          #       toggle_radio_group: "tag_operator",
          #       default_radio_value: "or"
          #     }
          #   )
          def create_all_checkbox(for_field_name:, **extra_config)
            base_name = for_field_name.to_s.delete_suffix("_ids").pluralize
            all_name = :"all_#{base_name}"

            Fields::Primitives::CheckboxField.new(
              name: all_name,
              label: I18n.t("basics.all"),
              checked: true,
              form_state: form_state,
              container_class: "form-check mb-2",
              stimulus: { toggle: true },
              **extra_config
            ).with_form(form)
          end

          # Creates a text input field with standard configuration.
          #
          # @param name [Symbol] The field name for form binding
          # @param label [String] The human-readable label
          # @param config [Hash] Additional options (placeholder, maxlength, etc.)
          # @return [Fields::Primitives::TextField] Configured text field
          #
          # @example From FulltextField
          #   create_text_field(
          #     name: :fulltext,
          #     label: I18n.t("basics.fulltext"),
          #     help_text: I18n.t("search.filters.helpdesks.fulltext_filter")
          #   )
          def create_text_field(**config)
            Fields::Primitives::TextField.new(
              form_state: form_state,
              **config
            ).with_form(form)
          end

          # Creates a select dropdown field with standard configuration.
          #
          # @param name [Symbol] The field name for form binding
          # @param label [String] The human-readable label
          # @param collection [Array] Array of [text, value] pairs for options
          # @param config [Hash] Additional options (selected, prompt, etc.)
          # @return [Fields::Primitives::SelectField] Configured select field
          #
          # @example From AnswerCountField
          #   create_select_field(
          #     name: :answers_count,
          #     label: I18n.t("basics.answer_count"),
          #     collection: [[1, 1], [2, 2], [3, 3], [">6", 7]],
          #     selected: "irrelevant"
          #   )
          #
          # @example From MediumAccessField
          #   create_select_field(
          #     name: :access,
          #     label: I18n.t("basics.access_rights"),
          #     collection: [
          #       [I18n.t("access.irrelevant"), "irrelevant"],
          #       [I18n.t("access.all"), "all"]
          #     ]
          #   )
          def create_select_field(**config)
            Fields::Primitives::SelectField.new(
              form_state: form_state,
              **config
            ).with_form(form)
          end

          # Creates a radio button field with standard configuration.
          # Typically used in groups to provide mutually exclusive options.
          #
          # @param name [Symbol] The field name (same for all radio buttons in a group)
          # @param value [String] The value this radio button represents
          # @param label [String] The human-readable label for this option
          # @param config [Hash] Additional options (checked, disabled, inline, etc.)
          # @return [Fields::Primitives::RadioButtonField] Configured radio button
          #
          # @example From LectureScopeField
          #   create_radio_button_field(
          #     name: :lecture_option,
          #     value: "0",
          #     label: I18n.t("search.radio_buttons.lecture_scope_filter.all"),
          #     checked: true,
          #     stimulus: { radio_toggle: true, controls_select: false }
          #   )
          #
          # @example From TagField (inline radio buttons)
          #   create_radio_button_field(
          #     name: :tag_operator,
          #     value: "or",
          #     label: I18n.t("search.radio_buttons.tag_field.OR"),
          #     inline: true,
          #     container_class: "form-check form-check-inline"
          #   )
          def create_radio_button_field(**config)
            Fields::Primitives::RadioButtonField.new(
              form_state: form_state,
              **config
            ).with_form(form)
          end

          # Creates a checkbox field with standard configuration.
          # Use this for standalone checkboxes or when you need custom checkbox behavior
          # (for "All" toggles, prefer create_all_checkbox).
          #
          # @param name [Symbol] The field name for form binding
          # @param label [String] The human-readable label
          # @param config [Hash] Additional options (checked, disabled, etc.)
          # @return [Fields::Primitives::CheckboxField] Configured checkbox field
          #
          # @example From TermIndependenceField
          #   create_checkbox_field(
          #     name: :term_independent,
          #     label: I18n.t("admin.course.term_independent"),
          #     help_text: I18n.t("search.filters.helpdesks.term_independence_filter"),
          #     checked: false
          #   )
          def create_checkbox_field(**config)
            Fields::Primitives::CheckboxField.new(
              form_state: form_state,
              **config
            ).with_form(form)
          end

          # Must be implemented by including class to define the field setup logic.
          # This method is called during the before_render lifecycle and should use
          # the create_* helper methods to build the composite field's components.
          #
          # @abstract
          # @return [void]
          # @raise [NotImplementedError] if not implemented by the including class
          def setup_fields
            raise(NotImplementedError, "#{self.class.name} must implement #setup_fields")
          end
      end
    end
  end
end
