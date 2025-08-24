module SearchForm
  module Fields
    # Multi-select field component for multiple value selection
    #
    # This field type renders a select dropdown that allows multiple selections.
    # It typically includes an "All" toggle checkbox for selecting/deselecting
    # all options at once. Used for filtering by multiple categories, tags,
    # or other multi-value criteria.
    #
    # Features:
    # - Multiple selection support
    # - Optional "All" toggle checkbox
    # - Integration with Stimulus for dynamic behavior
    # - Service objects for checkbox and data attribute management
    #
    # @param collection [Array] Array of options for the multi-select
    # @param all_toggle_name [String] Generated name for the "All" checkbox
    #
    # @example Basic multi-select field
    #   add_multi_select_field(
    #     name: :course_ids,
    #     label: "Courses",
    #     collection: courses_for_select,
    #     help_text: "Select one or more courses"
    #   )
    #
    # @example Multi-select without "All" checkbox
    #   add_multi_select_field(
    #     name: :tag_ids,
    #     label: "Tags",
    #     collection: tags_for_select,
    #     skip_all_checkbox: true
    #   )
    class MultiSelectField < Field
      attr_reader :collection, :all_toggle_name, :renderer, :checkbox_manager, :data_builder

      renders_one :checkbox, "SearchForm::Controls::Checkbox"

      def initialize(name:, label:, collection:, **options)
        @collection = collection
        @all_toggle_name = generate_all_toggle_name(name)

        super(
          name: name,
          label: label,
          **options
        )

        extract_and_update_field_classes!(options)

        # Initialize service objects
        @checkbox_manager = Services::CheckboxManager.new(self)
        @data_builder = Services::DataAttributesBuilder.new(self)
      end

      # Create the default checkbox in before_render
      # Checkboxes need helpdesk which requires application helpers
      # which are only available late.
      def before_render
        super
        return if respond_to?(:skip_all_checkbox?) && skip_all_checkbox?

        checkbox_manager.setup_default_checkbox
      end

      # Delegate to checkbox manager
      def show_checkbox?
        checkbox_manager.should_show_checkbox?
      end

      # HTML options for the select tag (4th parameter to form.select)
      def field_html_options(additional_options = {})
        html.field_html_options(additional_options.merge(data: data_builder.select_data_attributes))
      end

      # Hash passed as the (3rd) "options" argument to form.select
      delegate :select_tag_options, to: :html

      def show_radio_group?
        false
      end

      def all_checkbox_label
        I18n.t("basics.all")
      end

      def default_prompt
        true # Multi-select fields should have prompts by default
      end

      def default_field_classes
        ["selectize"] # Base selectize class for multi-select
      end

      private

        def generate_all_toggle_name(name)
          base_name = name.to_s.delete_suffix("_ids").pluralize
          :"all_#{base_name}"
        end

        def process_options(opts)
          opts.reverse_merge(
            multiple: true,
            disabled: true,
            required: true
          )
        end
    end
  end
end
