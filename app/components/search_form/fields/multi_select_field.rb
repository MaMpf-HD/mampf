module SearchForm
  module Fields
    # Renders a multi-select field, typically enhanced with a JavaScript library
    # like Selectize. Its key feature is an associated "All" checkbox that controls
    # the select input's state.
    #
    # By default, the component initializes with the "All" checkbox checked and the
    # select input disabled. Unchecking the box enables the select input, allowing
    # for specific selections. This provides a user-friendly way to switch between
    # searching all options and a specific subset.
    class MultiSelectField < Field
      attr_reader :collection, :all_toggle_name, :renderer, :checkbox_manager, :data_builder

      # Defines the `checkbox` slot, which is rendered by the template if present.
      # This slot is populated according to the following rules:
      # - A developer can manually provide a custom checkbox using the `with_checkbox` helper.
      # - If a custom checkbox is not provided, the `before_render` hook automatically
      #    creates a default "All" checkbox and populates this slot with it.
      # - This automatic creation can be prevented entirely if a subclass implements
      #    the `skip_all_checkbox?` hook to return `true`.
      # @!method checkbox(options = {})
      #   @param options [Hash] Options passed to the `SearchForm::Controls::Checkbox` component.
      #   @return [void]
      renders_one :checkbox, "SearchForm::Controls::Checkbox"

      # Initializes a new MultiSelectField.
      #
      # @param name [Symbol] The name of the field.
      # @param label [String] The label text for the field.
      # @param collection [Array] The collection of options for the select tag.
      # @param options [Hash] A hash of options passed to the base `Field`. This class
      #   uses the `process_options` hook and `default_prompt` method to set its own defaults:
      #   - `:multiple` defaults to `true`.
      #   - `:disabled` defaults to `true` (because the "All" checkbox is checked by default).
      #   - `:required` defaults to `true`.
      #   - `:prompt` defaults to `true` (overriding the base `Field` behavior).
      #   - `:selected` has no default.
      #   These can be overridden by passing them explicitly in the options hash.
      def initialize(name:, label:, collection:, skip_all_checkbox: false, **options)
        @collection = collection
        @all_toggle_name = generate_all_toggle_name(name)
        @skip_all_checkbox = skip_all_checkbox

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

      # A ViewComponent lifecycle callback that runs before rendering.
      # It sets up the default "All" checkbox unless a custom one has been
      # provided or the `skip_all_checkbox?` hook returns true.
      def before_render
        super
        return if respond_to?(:skip_all_checkbox?) && skip_all_checkbox?

        checkbox_manager.setup_default_checkbox
      end

      # Determines whether the "All" checkbox should be rendered.
      #
      # @return [Boolean]
      def show_checkbox?
        checkbox_manager.should_show_checkbox?
      end

      # Builds the HTML options hash for the `<select>` tag itself (the 4th
      # parameter to `form.select`). It merges in the necessary Stimulus
      # data attributes for toggling behavior.
      #
      # @param additional_options [Hash] Extra options to merge.
      # @return [Hash] The final HTML options hash.
      def field_html_options(additional_options = {})
        html.field_html_options(additional_options.merge(data: data_builder.select_data_attributes))
      end

      # Delegates to the HtmlBuilder to get the options hash for the `form.select`
      # helper (the 3rd parameter), which includes `:prompt` and `:selected`.
      delegate :select_tag_options, to: :html

      # A hook for subclasses to implement radio button functionality.
      #
      # @return [Boolean] Always `false` for this class.
      def show_radio_group?
        false
      end

      # Provides the translated label for the "All" checkbox.
      #
      # @return [String] The label text (e.g., "All").
      def all_checkbox_label
        I18n.t("basics.all")
      end

      # Overrides the base `Field` method to default to having a prompt.
      #
      # @return [Boolean] Always `true`.
      def default_prompt
        true # Multi-select fields should have prompts by default
      end

      # Provides default CSS classes for the `<select>` element.
      #
      # @return [Array<String>] An array containing the "selectize" class.
      def default_field_classes
        ["selectize"] # Base selectize class for multi-select
      end

      def skip_all_checkbox?
        @skip_all_checkbox
      end

      private

        # Generates the name for the "All" checkbox based on the field name.
        # e.g., :tag_ids -> :all_tags
        def generate_all_toggle_name(name)
          base_name = name.to_s.delete_suffix("_ids").pluralize
          :"all_#{base_name}"
        end

        # Merges default options required for a multi-select field.
        # These are reverse-merged, so they can be overridden by the user.
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
