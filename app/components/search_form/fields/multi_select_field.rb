module SearchForm
  module Fields
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
        @renderer = Services::MultiSelectRenderer.new(self)
        @checkbox_manager = Services::CheckboxManager.new(self)
        @data_builder = Services::DataAttributesBuilder.new(self)
      end

      # Create the default checkbox in before_render
      def before_render
        super
        return if respond_to?(:skip_all_checkbox?) && skip_all_checkbox?

        checkbox_manager.setup_default_checkbox
      end

      # Delegate to renderer
      delegate :options_html, to: :renderer

      delegate :grouped_collection?, to: :renderer

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
          :"all_#{name}"
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
