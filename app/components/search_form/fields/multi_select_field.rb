# app/components/search_form/fields/multi_select_field.rb
module SearchForm
  module Fields
    class MultiSelectField < Field
      attr_reader :collection, :all_toggle_name

      renders_one :checkbox, "SearchForm::Controls::Checkbox"

      def initialize(name:, label:, collection:, column_class: "col-5",
                     all_toggle_name: nil, **)
        @collection = collection
        @all_toggle_name = all_toggle_name || default_all_toggle_name(name)
        super(name: name, label: label, column_class: column_class, **)
      end

      # Create the default checkbox in before_render
      def before_render
        super
        setup_default_checkbox unless respond_to?(:skip_all_checkbox?) && skip_all_checkbox?
      end

      # HTML string with <option>/<optgroup> tags
      def options_html
        if grouped_collection?
          helpers.grouped_options_for_select(collection, selected_value)
        else
          helpers.options_for_select(collection, selected_value)
        end
      end

      # HTML options for the select tag (4th parameter to form.select)
      def select_html_options
        html_options_with_id(data: select_data_attributes)
      end

      # Hash passed as the (3rd) "options" argument to form.select
      def select_tag_options
        {} # extend later if we need :prompt etc.
      end

      # Whether to show checkbox
      def show_checkbox?
        checkbox.present?
      end

      def selected_value
        options[:selected]
      end

      def grouped_collection?
        first = collection.first
        first.is_a?(Array) &&
          first.last.is_a?(Array) &&
          first.last.first.is_a?(Array)
      end

      def all_checkbox_label
        I18n.t("basics.all")
      end

      private

        # Data attributes for the select element
        def select_data_attributes
          base_data = options[:data] || {}
          base_data.merge(search_form_target: "select")
        end

        # Setup the default checkbox if one wasn't provided
        def setup_default_checkbox
          with_checkbox(
            form_state: form_state,
            name: all_toggle_name,
            label: all_checkbox_label,
            checked: true,
            data: default_checkbox_data_attributes
          )
        end

        # Get data attributes for the default checkbox
        # Allows subclasses to override with custom attributes
        def default_checkbox_data_attributes
          if respond_to?(:all_toggle_data_attributes)
            all_toggle_data_attributes
          else
            {
              search_form_target: "allToggle",
              action: "change->search-form#toggleFromCheckbox"
            }
          end
        end

        def default_all_toggle_name(name)
          "all_#{name.to_s.sub(/_ids$/, "s")}"
        end

        def process_options(opts)
          opts.reverse_merge(
            multiple: true,
            class: "selectize",
            disabled: true,
            required: true
          )
        end
    end
  end
end
