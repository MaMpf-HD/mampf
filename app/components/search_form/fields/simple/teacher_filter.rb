module SearchForm
  module Filters
    # Renders a multi-select field for filtering by users who are teachers.
    # This component uses composition to build a multi-select field with an
    # "All" toggle checkbox, pre-configured with a specific name, label, and
    # a collection of teachers sourced from the `User.select_teachers` method.
    class TeacherFilter < ViewComponent::Base
      attr_accessor :form_state

      # Initializes the TeacherFilter.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `MultiSelectField`. The collection of teachers is
      # provided by the `User.select_teachers` class method.
      #
      # @param form_state [SearchForm::FormState] The form state object.
      # @param options [Hash] Additional options passed to the multi-select field.
      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
      end

      delegate :form, to: :form_state

      def with_form(form)
        form_state.with_form(form)
        self
      end

      def before_render
        setup_fields
      end

      private

        def setup_fields
          setup_multi_select_field
          setup_checkbox_group
        end

        def setup_multi_select_field
          @multi_select_field = Fields::MultiSelectField.new(
            name: :teacher_ids,
            label: I18n.t("basics.teachers"),
            help_text: I18n.t("search.filters.helpdesks.teacher_filter"),
            collection: User.select_teachers,
            form_state: form_state,
            skip_all_checkbox: true,
            **@options
          ).with_form(form)
        end

        def setup_checkbox_group
          setup_checkboxes
          @checkbox_group_wrapper = Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end

        def setup_checkboxes
          @all_checkbox = Fields::CheckboxField.new(
            name: generate_all_toggle_name(:teacher_ids),
            label: I18n.t("basics.all"),
            checked: true,
            form_state: form_state,
            container_class: "form-check mb-2",
            stimulus: {
              toggle: true
            }
          ).with_form(form)
        end

        def generate_all_toggle_name(name)
          base_name = name.to_s.delete_suffix("_ids").pluralize
          :"all_#{base_name}"
        end
    end
  end
end
