module Search
  class MultiSelectComponent < FormFieldComponent
    attr_reader :collection, :all_toggle_name

    renders_one :checkbox, "Search::Controls::CheckboxComponent"

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

    # Setup the default checkbox if one wasn't provided
    def setup_default_checkbox
      with_checkbox(
        form: form,
        name: all_toggle_name,
        label: all_checkbox_label,
        checked: true,
        data: if respond_to?(:all_toggle_data_attributes)
                all_toggle_data_attributes
              else
                {
                  search_form_target: "allToggle",
                  action: "change->search-form#toggleFromCheckbox"
                }
              end
      )
    end

    # Hash passed as the (3rd) "options" argument to form.select
    def select_tag_options
      {} # extend later if you need :prompt etc.
    end

    # Hash passed as the HTML options (4th arg) to form.select
    def select_html_options
      # Remove :selected so it isn’t duplicated in the tag attributes
      options.except(:selected)
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
