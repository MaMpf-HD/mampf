module SearchForm
  module Utilities
    # A lightweight utility class that provides accessibility markup for radio button groups.
    # Can automatically extract legend and aria-labelledby from a parent field.
    class RadioGroupWrapper
      attr_reader :name, :legend, :options, :parent_field, :radio_buttons

      def initialize(name: nil, parent_field: nil, radio_buttons: [], legend: nil,
                     legend_class: "visually-hidden", **options)
        @name = name
        @parent_field = parent_field
        @radio_buttons = radio_buttons
        @legend = legend
        @legend_class = legend_class
        @options = options
      end

      # Add radio buttons to the wrapper
      def with_radio_buttons(*buttons)
        @radio_buttons = buttons.flatten
        self
      end

      # Renders the fieldset wrapper with proper accessibility markup
      def render(view_context = nil, &)
        if view_context
          render_with_context(view_context, &)
        else
          render_with_context(self, &)
        end
      end

      # Allow the wrapper to be used with <%= %> in templates
      def wrap(view_context, &)
        render_with_context(view_context, &)
      end

      private

        def render_with_context(context, &block)
          context.content_tag(:fieldset, fieldset_options) do
            content = []

            if resolved_legend.present?
              content << context.content_tag(:legend, resolved_legend, class: @legend_class)
            end

            if block
              content << context.capture(&block)
            elsif @radio_buttons.any?
              # Auto-render the radio buttons if no block is provided
              content << context.content_tag(:div, class: "mt-2") do
                context.safe_join(@radio_buttons.map { |button| context.render(button) })
              end
            end

            context.safe_join(content)
          end
        end

        def fieldset_options
          base_options = {
            role: "radiogroup",
            class: options[:class]
          }

          # Use resolved aria-labelledby
          if resolved_aria_labelledby.present?
            base_options[:"aria-labelledby"] = resolved_aria_labelledby
          end

          base_options
        end

        # Resolve legend from explicit value, parent field, or radio button name
        def resolved_legend
          return @legend if @legend.present?
          return "#{@parent_field.label} options" if @parent_field&.label.present?
          return "#{@name.to_s.humanize} options" if @name

          "Radio group options"
        end

        # Resolve aria-labelledby from explicit value or parent field
        def resolved_aria_labelledby
          return options[:"aria-labelledby"] if options[:"aria-labelledby"]
          return @parent_field.form_state.element_id_for(@parent_field.name) if @parent_field

          nil
        end
    end
  end
end
