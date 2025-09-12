module SearchForm
  module Fields
    module Utilities
      # Wraps a collection of radio button components within a `fieldset` element
      # with `role="radiogroup"`. This is essential for accessibility, as it
      # semantically groups related radio buttons under a common legend.
      class RadioGroupWrapper
        include GroupWrapperShared

        attr_reader :name, :legend, :radio_buttons

        # Initializes the wrapper.
        #
        # @param name [Symbol, String] The name for the radio button group, used to generate a default legend.
        # @param parent_field [Field] The parent field component that this group is associated with.
        #   Used to automatically resolve the `aria-labelledby` attribute.
        # @param radio_buttons [Array<RadioButtonField>] A list of radio button component instances to be wrapped.
        # @param legend [String] The text for the fieldset's legend. If nil, a default is generated.
        # @param legend_class [String] The CSS class for the legend element. Defaults to "visually-hidden".
        # @param options [Hash] A hash of additional HTML attributes to be applied to the fieldset.
        def initialize(name: nil, parent_field: nil, radio_buttons: [], legend: nil,
                       legend_class: "visually-hidden", **options)
          @name = name
          @parent_field = parent_field
          @radio_buttons = radio_buttons
          @legend = legend
          @legend_class = legend_class
          @options = options
        end

        # Sets the radio buttons to be rendered by the wrapper.
        #
        # @param buttons [Array<RadioButtonField>] A list of radio button component instances.
        # @return [self] Returns the instance for method chaining.
        def with_radio_buttons(*buttons)
          @radio_buttons = buttons.flatten
          self
        end

        # Renders the fieldset and its contents.
        # It creates a `fieldset` with `role="radiogroup"` and an appropriate
        # legend. Inside, it renders the collection of radio buttons.
        #
        # @param view_context [ActionView::Base] The view context for rendering.
        # @param &block A block that can be used to render custom content inside the group.
        # @return [ActiveSupport::SafeBuffer] The HTML-safe string representing the rendered group.
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

          # Builds the hash of HTML attributes for the fieldset element.
          # It sets the `role` to "radiogroup" and merges any custom classes.
          # It also adds `aria-labelledby` if a parent field is present.
          def fieldset_options
            base_options = { role: "radiogroup", class: @options[:class] }
            if resolved_aria_labelledby.present?
              base_options[:"aria-labelledby"] =
                resolved_aria_labelledby
            end
            base_options
          end

          # Resolves the text for the fieldset's legend.
          # It prioritizes an explicitly passed `:legend` option. If not present,
          # it falls back to generating a legend from the parent field's label or
          # the group's name.
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
