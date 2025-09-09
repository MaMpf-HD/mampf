module SearchForm
  module Filters
    class TagFilter < ViewComponent::Base
      attr_accessor :form_state

      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
        @show_radio_group = false
      end

      delegate :form, to: :form_state

      def with_form(form)
        form_state.with_form(form)
        self
      end

      def with_operator_radios
        @show_radio_group = true
        self
      end

      def call
        render_select_field
      end

      private

        def render_select_field
          multi_select = Fields::MultiSelectField.new(
            name: :tag_ids,
            label: I18n.t("basics.tags"),
            help_text: I18n.t("search.filters.helpdesks.tag_filter"),
            collection: [],
            form_state: form_state,
            skip_all_checkbox: true, # We'll add our own custom checkbox
            data: {
              filled: false,
              ajax: true,
              model: "tag",
              locale: I18n.locale,
              placeholder: I18n.t("basics.select"),
              no_results: I18n.t("basics.no_results")
            }
          )

          # Add custom checkbox with radio group toggle attributes
          multi_select.with_checkbox(
            name: generate_all_toggle_name(:tag_ids),
            label: I18n.t("basics.all"),
            checked: true,
            form_state: form_state,
            data: all_toggle_data_attributes
          )

          # Add the radio group content using the RadioGroupWrapper
          if @show_radio_group
            multi_select.with_content do
              wrapper = Utilities::RadioGroupWrapper.new(
                name: :tag_operator,
                legend: "#{I18n.t("basics.tags")}\n        options\n      ",
                legend_class: "visually-hidden",
                "aria-labelledby": form_state.element_id_for(:tag_ids)
              )

              wrapper.render(helpers) do
                content_tag(:div, class: "mt-2") do
                  safe_join([
                              render_or_radio_button,
                              render_and_radio_button
                            ])
                end
              end
            end
          end

          multi_select.with_form(form)
          render(multi_select)
        end

        def render_or_radio_button
          render(Fields::RadioButtonField.new(
            name: :tag_operator,
            value: "or",
            label: I18n.t("basics.OR"),
            checked: true,
            form_state: form_state,
            disabled: true,
            inline: true,
            container_class: "form-check form-check-inline", # Override to match old version
            stimulus: { radio_toggle: true, controls_select: false }
          ).with_form(form))
        end

        def render_and_radio_button
          render(Fields::RadioButtonField.new(
            name: :tag_operator,
            value: "and",
            label: I18n.t("basics.AND"),
            checked: false,
            form_state: form_state,
            disabled: true,
            inline: true,
            container_class: "form-check form-check-inline", # Override to match old version
            stimulus: { radio_toggle: true, controls_select: false }
          ).with_form(form))
        end

        # Copy the exact data attributes from the old TagFilter
        def all_toggle_data_attributes
          {
            search_form_target: "allToggle",
            action: "change->search-form#toggleFromCheckbox change->search-form#toggleRadioGroup",
            toggle_radio_group: "tag_operator",
            default_radio_value: "or"
          }
        end

        def generate_all_toggle_name(name)
          base_name = name.to_s.delete_suffix("_ids").pluralize
          :"all_#{base_name}"
        end
    end
  end
end
