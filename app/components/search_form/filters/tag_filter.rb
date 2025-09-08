module SearchForm
  module Filters
    class TagFilter < ViewComponent::Base
      attr_accessor :form_state

      def initialize(form_state:, show_operator_radios: false, **)
        super()
        @form_state = form_state
        @show_radio_group = show_operator_radios
      end

      # This method makes the filter compatible with the SearchForm's render loop.
      # It injects the form builder into the form_state, making it available
      # to the fields rendered by this filter's template.
      def with_form(form)
        form_state.with_form(form)
        self # Return self to allow `render` to work on the component
      end

      delegate :form, to: :form_state

      # Optional builder hook (kept for API compatibility)
      def with_operator_radios
        @show_radio_group = true
        self
      end

      def show_radio_group?
        @show_radio_group
      end

      # Helpers used by the template
      def select_field
        Fields::MultiSelectField.new(
          name: :tag_ids,
          label: I18n.t("basics.tags"),
          help_text: I18n.t("search.filters.helpdesks.tag_filter"),
          collection: [], # filled via AJAX
          form_state: form_state,
          data: {
            filled: false,
            ajax: true,
            model: "tag",
            locale: I18n.locale,
            placeholder: I18n.t("basics.select"),
            no_results: I18n.t("basics.no_results")
          }
        ).with_form(form)
      end

      def radio_group
        Fields::RadioGroupField.new(
          name: :tag_operator,
          form_state: form_state
        ).with_form(form)
      end

      # Builder helpers for the two operator radios (rendered inside the group's block)
      def tag_operator_radio(value:, label:, checked:)
        Fields::RadioButtonField.new(
          name: :tag_operator,
          value: value,
          label: label,
          checked: checked,
          disabled: true,
          inline: true,
          form_state: form_state,
          stimulus: { radio_toggle: true, controls_select: false }
        ).with_form(form)
      end

      # FOR DEBUGGING
      def test_radio_button_1
        Fields::RadioButtonField.new(
          name: :test_operator,
          value: "or",
          label: "Test OR",
          checked: true,
          form_state: form_state
        ).with_form(form)
      end

      def test_radio_button_2
        Fields::RadioButtonField.new(
          name: :test_operator,
          value: "and",
          label: "Test AND",
          checked: false,
          form_state: form_state
        ).with_form(form)
      end

      def radio_group_fieldset(name:, legend:, form_state:,
                               container_class: "col-6 col-lg-3 mb-3 form-field-group", fieldset_attrs: {}, &block)
        group_label_id = form_state.element_id_for(name, "group")

        content_tag(:div, class: container_class) do
          content_tag(
            :fieldset,
            {
              role: "radiogroup",
              aria: { labelledby: group_label_id }
            }.deep_merge(fieldset_attrs)
          ) do
            concat(content_tag(:legend, "#{legend} options", id: group_label_id,
                                                             class: "visually-hidden"))
            concat(capture(&block))
          end
        end
      end
    end
  end
end
