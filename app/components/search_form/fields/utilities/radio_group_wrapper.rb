module SearchForm
  module Fields
    module Utilities
      class RadioGroupWrapper
        include GroupWrapperShared

        attr_reader :name, :legend, :radio_buttons

        def initialize(name: nil, parent_field: nil, radio_buttons: [], legend: nil,
                       legend_class: "visually-hidden", **options)
          @name = name
          @parent_field = parent_field
          @radio_buttons = radio_buttons
          @legend = legend
          @legend_class = legend_class
          @options = options
        end

        def with_radio_buttons(*buttons)
          @radio_buttons = buttons.flatten
          self
        end

        # Renders the fieldset and its contents.
        #
        # SECURITY: This method uses `safe_join` to concatenate the legend and the
        # rendered radio buttons. Both `content_tag` and `auto_render_collection`
        # return HTML-safe strings. The security of this method therefore relies
        # on the security of the individual radio button components being rendered.
        def render(view_context = nil, &block)
          context = view_context || self
          context.content_tag(:fieldset, fieldset_options) do
            content = []
            if resolved_legend.present?
              content << context.content_tag(:legend, resolved_legend,
                                             class: @legend_class)
            end
            content << auto_render_collection(context, @radio_buttons, wrapper_class: "mt-2",
                                              &block)
            context.safe_join(content)
          end
        end

        private

          def fieldset_options
            base_options = { role: "radiogroup", class: @options[:class] }
            if resolved_aria_labelledby.present?
              base_options[:"aria-labelledby"] =
                resolved_aria_labelledby
            end
            base_options
          end

          def resolved_legend
            return @legend if @legend.present?
            return "#{@parent_field.label} options" if @parent_field&.label.present?
            return "#{@name.to_s.humanize} options" if @name

            "Radio group options"
          end
      end
    end
  end
end
