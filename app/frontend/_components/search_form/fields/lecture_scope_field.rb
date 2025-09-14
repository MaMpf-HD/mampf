module SearchForm
  module Fields
    # Renders a multi-select field for filtering by lectures with radio button controls
    # for different selection modes. This component combines a multi-select dropdown
    # with radio buttons that control how lecture filtering behaves.
    #
    # The field provides three selection modes:
    # - "All": Shows content from all lectures (multi-select is disabled)
    # - "Subscribed": Shows content from user's subscribed lectures (multi-select is disabled)
    # - "Own Selection": Enables the multi-select for manual lecture selection
    #
    # This pattern allows users to quickly switch between common filtering scenarios
    # while still providing the flexibility of manual selection when needed.
    #
    # @example Basic lecture scope field
    #   LectureScopeField.new(form_state: form_state)
    #
    # @example Lecture scope field with additional options
    #   LectureScopeField.new(
    #     form_state: form_state,
    #     disabled: false,
    #     data: { custom_attribute: "value" }
    #   )
    class LectureScopeField < ViewComponent::Base
      include Mixins::CompositeFieldMixin

      attr_reader :options

      # Initializes a new LectureScopeField component.
      #
      # @param form_state [SearchForm::FormState] The form state object for context
      # @param options [Hash] Additional options passed to the underlying multi-select field
      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
      end

      private

        def setup_fields
          @multi_select_field = create_multi_select_field(
            name: :lectures,
            label: I18n.t("basics.lectures"),
            help_text: I18n.t("search.fields.helpdesks.lecture_scope_field"),
            collection: lecture_options,
            **options
          )

          @all_radio = create_radio_button_field(
            name: :lecture_option,
            value: "0",
            label: I18n.t("search.radio_buttons.lecture_scope_field.all"),
            checked: true,
            disabled: false,
            inline: false,
            container_class: "form-check",
            stimulus: { radio_toggle: true, controls_select: false }
          )

          @subscribed_radio = create_radio_button_field(
            name: :lecture_option,
            value: "1",
            label: I18n.t("search.radio_buttons.lecture_scope_field.subscribed"),
            checked: false,
            disabled: false,
            inline: false,
            container_class: "form-check",
            stimulus: { radio_toggle: true, controls_select: false }
          )

          @own_selection_radio = create_radio_button_field(
            name: :lecture_option,
            value: "2",
            label: I18n.t("search.radio_buttons.lecture_scope_field.own_selection"),
            checked: false,
            disabled: false,
            inline: false,
            container_class: "form-check",
            stimulus: { radio_toggle: true, controls_select: true }
          )

          @radio_group_wrapper = Fields::Utilities::RadioGroupWrapper.new(
            name: :lecture_option,
            parent_field: @multi_select_field,
            radio_buttons: [@all_radio, @subscribed_radio, @own_selection_radio]
          )
        end

        def lecture_options
          Lecture.includes(:course, :term)
                 .map { |l| [l.title, l.id] }
                 .natural_sort_by(&:first)
        end
    end
  end
end
