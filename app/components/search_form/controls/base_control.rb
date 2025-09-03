module SearchForm
  module Controls
    # BaseControl is an abstract base class for individual form controls like
    # checkboxes and radio buttons. It provides a shared foundation for common
    # functionality required by these controls, including:
    #
    # - Integration with `FormState` for unique ID generation.
    # - A consistent interface for HTML options and CSS classes.
    # - A structure for handling Stimulus.js data attributes in subclasses.
    #
    # Subclasses are expected to implement the `#id_parts` method to define their
    # specific portion of the HTML ID and may override `#data_attributes` to add
    # Stimulus-related functionality.
    class BaseControl < ViewComponent::Base
      attr_accessor :form_state
      attr_reader :options, :stimulus_config, :help_text

      # Initializes a new BaseControl instance.
      #
      # @param form_state [SearchForm::Services::FormState] The shared form state object.
      # @param stimulus [Hash] Configuration for Stimulus.js controllers, to be used by subclasses.
      # @param help_text [String] Help text to be displayed alongside the control.
      # @param options [Hash] A hash of standard HTML options (e.g., class, data).
      def initialize(form_state:, stimulus: {}, help_text: nil, **options)
        super()
        @form_state = form_state
        @stimulus_config = stimulus
        @help_text = help_text
        @options = options
      end

      delegate :form, to: :form_state
      delegate :context, to: :form_state

      # Generates the full, unique HTML ID for the control's <input> element.
      #
      # @return [String] The full element ID, including form scope and context.
      def element_id
        form_state.element_id_for(*id_parts)
      end

      # Generates the identifier for a <label>'s `for` attribute.
      #
      # @return [String] The identifier, which the form builder will scope correctly.
      def label_for
        form_state.label_for(*id_parts)
      end

      # Returns the CSS class(es) for the control's wrapping container element.
      # Prioritizes a passed-in class over the default.
      #
      # @return [String] The CSS class string.
      def container_class
        options[:container_class] || default_container_class
      end

      # Provides the default CSS class for the container.
      #
      # @return [String] The default CSS class.
      def default_container_class
        "form-check mb-2"
      end

      # Builds the base hash of data attributes to be applied to the control.
      # This method provides any data attributes passed in via the `options` hash.
      # Subclasses are expected to call `super` and merge their own
      # stimulus-driven attributes into this base hash.
      #
      # @return [Hash] A hash of data attributes.
      def data_attributes
        options[:data] || {}
      end

      # Prepares the final hash of HTML options to be passed to a Rails form helper.
      # It includes data attributes and filters out internal options like `:container_class`.
      #
      # @return [Hash] A clean hash of HTML options.
      def html_options
        result = {}
        result[:data] = data_attributes if data_attributes.any?
        result.merge(options.except(:container_class))
      end

      # Injects the form builder into the `form_state` object.
      # This is called during the rendering process.
      #
      # @param form [ActionView::Helpers::FormBuilder] The form builder instance.
      # @return [self] Returns itself to allow for method chaining.
      def with_form(form)
        form_state.with_form(form)
        self
      end

      # @return [Boolean] True if help text should be displayed inline
      def show_inline_help_text?
        help_text.present?
      end

      # @return [String] The help text ID for accessibility
      def help_text_id
        "#{element_id}_help"
      end

      private

        # This private method must be implemented by subclasses.
        # It should return an array of strings or symbols that uniquely identify
        # this control within its field. These parts are used by `FormState`
        # to generate the final HTML IDs.
        def id_parts
          raise(NotImplementedError, "#{self.class.name} must implement #id_parts")
        end
    end
  end
end
