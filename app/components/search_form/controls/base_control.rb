# Search Form Controls Module
#
# This module contains reusable UI control components for search forms.
# Controls are lower-level components that render specific input elements
# like checkboxes, radio buttons, and radio groups.
#
# Control architecture:
# - BaseControl: Foundation class with common control functionality
# - Checkbox: Individual checkbox input with label
# - RadioButton: Individual radio button input with label
# - RadioGroup: Container for multiple radio buttons with shared name
#
# All controls integrate with:
# - FormState for ID generation and form access
# - Stimulus for JavaScript behaviors
# - Bootstrap CSS classes for consistent styling

module SearchForm
  module Controls
    # Base control class for all form input controls
    #
    # This class provides foundational functionality that all control types inherit.
    # It handles form state management, ID generation, Stimulus integration,
    # and common styling concerns.
    #
    # @param form_state [FormState] The form state object for dependency injection
    # @param stimulus [Hash] Stimulus controller configuration for JavaScript behaviors
    # @param options [Hash] Additional options for control configuration
    #
    # @example Basic control initialization
    #   control = BaseControl.new(
    #     form_state: form_state,
    #     stimulus: { controller: "toggle", action: "click->toggle#change" }
    #   )
    #
    # @example Control with custom styling
    #   control = BaseControl.new(
    #     form_state: form_state,
    #     container_class: "form-check-inline",
    #     field_class: "form-check-input"
    #   )
    class BaseControl < ViewComponent::Base
      attr_accessor :form_state
      attr_reader :options, :stimulus_config

      def initialize(form_state:, stimulus: {}, **options)
        super()
        @form_state = form_state
        @stimulus_config = stimulus
        @options = options
      end

      delegate :form, to: :form_state
      delegate :context, to: :form_state

      # The public ID for the <input> element itself
      def element_id
        form_state.element_id_for(*id_parts)
      end

      # The public ID for the <label for="..."> attribute
      def label_for
        form_state.label_for(*id_parts)
      end

      # Keep all your existing methods unchanged
      def container_class
        options[:container_class] || default_container_class
      end

      def default_container_class
        "form-check mb-2"
      end

      def data_attributes
        return options[:data] || {} if stimulus_config.empty?

        options[:data] || {}
      end

      def html_options
        result = {}
        result[:data] = data_attributes if data_attributes.any?
        result.merge(options.except(:container_class))
      end

      def with_form(form)
        form_state.with_form(form)
        self
      end

      private

        def id_parts
          raise(NotImplementedError, "#{self.class.name} must implement #id_parts")
        end
    end
  end
end
