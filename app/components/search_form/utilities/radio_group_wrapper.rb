module SearchForm
  module Utilities
    # A lightweight utility class that provides accessibility markup for radio button groups.
    # This replaces the complex Controls::RadioGroup with a simple fieldset wrapper.
    class RadioGroupWrapper
      attr_reader :name, :legend, :options

      def initialize(name:, legend: nil, legend_class: "visually-hidden", **options)
        @name = name
        @legend = legend
        @legend_class = legend_class
        @options = options
      end

      # Renders the fieldset wrapper with proper accessibility markup
      def render(view_context, &block)
        view_context.content_tag(:fieldset, fieldset_options) do
          content = []

          if @legend.present?
            content << view_context.content_tag(:legend, @legend, class: @legend_class)
          end

          content << view_context.capture(&block) if block

          view_context.safe_join(content)
        end
      end

      private

        def fieldset_options
          base_options = {
            role: "radiogroup",
            class: options[:class]
          }

          if options[:"aria-labelledby"]
            base_options[:"aria-labelledby"] =
              options[:"aria-labelledby"]
          end
          base_options
        end
    end
  end
end
