module SearchForm
  module Fields
    module Services
      # Serves as the composition root for field components, holding all field-specific
      # data and providing access to CSS management and HTML building services.
      #
      # It uses a composition-based approach, allowing field components to delegate
      # common functionality (like HTML and CSS generation) while maintaining
      # flexibility for field-specific rendering logic.
      #
      # The class manages:
      # - Field identification (name, label)
      # - Display configuration (help text, container styling)
      # - Form integration (form state, form builder)
      # - Service objects (CSS manager, HTML builder)
      # - Content blocks for complex field layouts
      #
      # @example Creating field data for a text input
      #   field_data = FieldData.new(
      #     name: :email,
      #     label: "Email Address",
      #     form_state: form_state,
      #     help_text: "We'll never share your email",
      #     options: { placeholder: "Enter email", required: true }
      #   )
      #
      # @example Field data with select-specific attributes
      #   field_data = FieldData.new(
      #     name: :category,
      #     label: "Category",
      #     form_state: form_state,
      #     prompt: "Choose a category...",
      #     selected: "electronics"
      #   )
      class FieldData
        # Core field identification and display attributes
        attr_reader :name, :label, :help_text, :options, :prompt,
                    :multiple, :disabled, :required, :selected,
                    :value, :use_value_in_id, :css, :html

        # Layout and styling attributes that can be modified after initialization
        attr_accessor :container_class, :field_class, :form_state

        # Initializes a new FieldData instance with field attributes and services.
        #
        # @param name [Symbol] The field name used for form binding and ID generation
        # @param label [String] The human-readable label text displayed to users
        # @param form_state [FormState] The form state object providing form context
        # @param help_text [String, nil] Optional help text for user guidance
        # @param options [Hash] HTML attributes and field configuration options
        # @param multiple [Boolean, nil] Whether the field allows multiple selections
        # (select fields)
        # @param disabled [Boolean, nil] Whether the field is disabled
        # @param required [Boolean, nil] Whether the field is required for form submission
        # @param prompt [String, Boolean, nil] Prompt text or boolean for select fields
        # @param selected [Object, nil] Pre-selected value(s) for the field
        # @param value [String, Symbol, nil] The value for a specific option (e.g., a radio button)
        # @param use_value_in_id [Boolean] If true, the `value` will be included
        # in the generated ID.
        #
        # This method intentionally accepts many parameters because this class acts as a
        # Parameter Object. Each keyword argument represents a distinct, core configuration
        # option for a field, and keeping them explicit improves API discoverability.
        # rubocop:disable Metrics/ParameterLists
        def initialize(name:, label:, form_state:, help_text: nil, options: {},
                       multiple: nil, disabled: nil, required: nil, prompt: nil,
                       selected: nil, value: nil, use_value_in_id: false)
          @name = name
          @label = label
          @help_text = help_text
          @form_state = form_state
          @multiple = multiple
          @disabled = disabled
          @required = required
          @prompt = prompt
          @selected = selected
          @value = value
          @use_value_in_id = use_value_in_id
          @content_block = nil

          # Extract and set layout options with Bootstrap-friendly defaults
          extract_layout_options(options)

          # Store remaining options for HTML attribute generation
          @options = options

          # Initialize service objects for CSS and HTML management
          initialize_services
        end
        # rubocop:enable Metrics/ParameterLists

        # Delegates form builder access to the form state
        delegate :form, to: :form_state

        # Delegates form context access to the form state
        delegate :context, to: :form_state

        # Determines whether help text should be displayed.
        # Used by templates and accessibility attribute builders.
        #
        # @return [Boolean] true if help text is present and should be shown
        def show_help_text?
          help_text.present?
        end

        # Determines whether a content block has been associated with this field.
        # Content blocks are used for complex field layouts with additional controls.
        #
        # @return [Boolean] true if a content block has been set
        def show_content?
          @content_block.present?
        end

        # Associates a content block with this field and returns self for method chaining.
        # Content blocks enable fields to render additional content like buttons,
        # nested controls, or custom help text.
        #
        # @param block [Proc] The content block to associate with this field
        # @return [self] Returns self to enable method chaining
        def with_content(&block)
          @content_block = block if block
          self
        end

        # Provides access to the content block for template rendering.
        # Templates can check for content presence and render it appropriately.
        #
        # @return [Proc, nil] The associated content block or nil if none exists
        def content
          @content_block
        end

        # Provides default CSS classes for field elements.
        # This method is designed to be overridden via `define_singleton_method`
        # by field components to specify their default styling.
        #
        # @return [Array<String>] Array of default CSS class names
        def default_field_classes
          []
        end

        # Extracts CSS classes from options and updates the field_class attribute.
        # This method combines default field classes with user-provided classes,
        # following the same pattern as the legacy Field class architecture.
        #
        # @param options [Hash] The options hash to extract classes from
        # @return [void]
        def extract_and_update_field_classes!(options)
          extracted_classes = css.extract_field_classes(options)
          @field_class = [field_class, extracted_classes].compact.join(" ").strip
        end

        # ViewComponent lifecycle hook that validates field configuration.
        # Ensures that a form builder has been associated with the field before
        # rendering, preventing runtime errors from missing form context.
        #
        # @raise [RuntimeError] If no form builder has been set
        # @return [void]
        def before_render
          raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
        end

        private

          # Extracts layout-related options and sets appropriate defaults.
          # Separates layout configuration from HTML attributes, following
          # Bootstrap form layout conventions.
          #
          # @param options [Hash] The options hash to extract from
          # @return [void]
          def extract_layout_options(options)
            @container_class = options.delete(:container_class) ||
                               "col-6 col-lg-3 mb-3 form-field-group"
            @field_class = options.delete(:field_class) || ""
          end

          # Initializes CSS and HTML service objects.
          # These services handle the complexity of building CSS class strings
          # and HTML attribute hashes for form elements.
          #
          # @return [void]
          def initialize_services
            @css = Services::CssManager.new(self)
            @html = Services::HtmlBuilder.new(self)
          end
      end
    end
  end
end
