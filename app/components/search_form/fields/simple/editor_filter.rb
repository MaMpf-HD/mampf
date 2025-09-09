module SearchForm
  module Filters
    # Renders a multi-select field for filtering by users who are editors.
    # This component uses composition to build a multi-select field with an
    # "All" toggle checkbox for selecting/deselecting all editors.
    class EditorFilter < ViewComponent::Base
      attr_accessor :form_state

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
            name: :editor_ids,
            label: I18n.t("basics.editors"),
            help_text: I18n.t("search.filters.helpdesks.editor_filter"),
            collection: editor_options,
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
            name: generate_all_toggle_name(:editor_ids),
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

        # This private method is responsible for building the collection.
        # Its logic generates a list of all distinct users who are editors,
        # formatting their display name as "Tutorial Name (email)" or "Full Name (email)",
        # and then sorting the list alphabetically.
        def editor_options
          User.joins(:editable_user_joins)
              .distinct
              .pluck(:id, :name, :name_in_tutorials, :email)
              .map do |id, name, name_in_tutorials, email|
                display_name = "#{name_in_tutorials.presence || name} (#{email})"
                [display_name, id]
              end
              .natural_sort_by(&:first)
        end
    end
  end
end
