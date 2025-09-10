module SearchForm
  module Fields
    # Renders a multi-select field for filtering by terms.
    # This component is a simple specialization that uses composition to build
    # a multi-select field with an "All" toggle checkbox, pre-configured
    # with a specific name, label, and a collection of terms sourced
    # from the `Term.select_terms` method.
    class TermField < ViewComponent::Base
      attr_accessor :form_state

      # Initializes the TermField.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `MultiSelectField`. The collection of terms is
      # provided by the `Term.select_terms` class method.
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
          @multi_select_field = Fields::Primitives::MultiSelectField.new(
            name: :term_ids,
            label: I18n.t("basics.term"),
            help_text: I18n.t("search.filters.helpdesks.term_filter"),
            collection: Term.select_terms,
            form_state: form_state,
            skip_all_checkbox: true,
            **@options
          ).with_form(form)
        end

        def setup_checkbox_group
          setup_checkboxes
          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end

        def setup_checkboxes
          @all_checkbox = Fields::Primitives::CheckboxField.new(
            name: generate_all_toggle_name(:term_ids),
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
