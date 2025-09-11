module SearchForm
  module Fields
    # Renders a multi-select field for filtering by users who are editors.
    # This component uses composition to build a multi-select field with an
    # "All" toggle checkbox that controls the selection state of all editor options.
    #
    # The field displays editors with their display names formatted as either
    # "Tutorial Name (email)" or "Full Name (email)", sorted alphabetically.
    # This provides a user-friendly way to filter content by specific editors
    # while offering a convenient toggle to select or deselect all editors.
    #
    # @example Basic editor field
    #   EditorField.new(form_state: form_state)
    #
    # @example Editor field with additional options
    #   EditorField.new(
    #     form_state: form_state,
    #     disabled: false,
    #     data: { custom_attribute: "value" }
    #   )
    class EditorField < ViewComponent::Base
      include Mixin::FieldSetupMixin

      attr_reader :options

      # Initializes a new EditorField component.
      #
      # @param form_state [SearchForm::FormState] The form state object for context
      # @param options [Hash] Additional options passed to the underlying multi-select field
      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
      end

      private

        def setup_fields
          @multi_select_field = create_multi_select_field(
            name: :editor_ids,
            label: I18n.t("basics.editors"),
            help_text: I18n.t("search.fields.helpdesks.editor_field"),
            collection: editor_options,
            **options
          )

          @all_checkbox = create_all_checkbox(for_field_name: :editor_ids)

          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end

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
