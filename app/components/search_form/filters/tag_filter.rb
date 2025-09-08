module SearchForm
  module Filters
    # Renders a multi-select field for filtering by tags. This component
    # now uses composition instead of inheritance - it coordinates a
    # MultiSelectField and RadioButtonFields rather than inheriting from MultiSelectField.
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

      # A configuration method to enable the rendering of the "AND/OR" operator
      # radio button group.
      #
      # @return [self] Returns the component instance to allow for method chaining.
      def with_operator_radios
        @show_radio_group = true
        self
      end

      # The main render method that composes the filter from multiple fields
      def call
        content_tag(:div, class: "col-6 col-lg-3 mb-3 form-field-group") do
          safe_join([
            render_select_field,
            render_radio_group
          ].compact)
        end
      end

      private

        def render_select_field
          render(Fields::MultiSelectField.new(
            name: :tag_ids,
            label: I18n.t("basics.tags"),
            help_text: I18n.t("search.filters.helpdesks.tag_filter"),
            collection: [], # Empty - will be loaded via AJAX
            form_state: form_state,
            data: {
              filled: false,
              ajax: true,
              model: "tag",
              locale: I18n.locale,
              placeholder: I18n.t("basics.select"),
              no_results: I18n.t("basics.no_results")
            }
          ).with_form(form))
        end

        def render_radio_group
          return unless @show_radio_group

          wrapper = Utilities::RadioGroupWrapper.new(
            name: :tag_operator,
            legend: nil # No legend needed for this group
          )

          wrapper.render(helpers) do
            safe_join([
                        render_or_radio_button,
                        render_and_radio_button
                      ])
          end
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
            stimulus: { radio_toggle: true, controls_select: false }
          ).with_form(form))
        end
    end
  end
end
