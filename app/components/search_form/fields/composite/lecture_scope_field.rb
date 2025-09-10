module SearchForm
  module Fields
    # Renders a multi-select field for filtering by lectures. This component
    # uses composition to build a multi-select field with optional radio button groups
    # for different lecture selection modes (All, Subscribed, Own Selection).
    class LectureScopeField < ViewComponent::Base
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

      # A configuration method to enable the rendering of the radio button group.
      #
      # @return [self] Returns the component instance to allow for method chaining.
      def with_lecture_options
        @show_radio_group = true
        self
      end

      # A helper method for the template to determine if the radio button group
      # should be rendered.
      #
      # @return [Boolean] `true` if the radio group has been enabled via `with_lecture_options`.
      def show_radio_group?
        @show_radio_group
      end

      def before_render
        setup_fields
      end

      private

        def setup_fields
          setup_multi_select_field
          setup_radio_group if @show_radio_group
        end

        def setup_multi_select_field
          @multi_select_field = Fields::MultiSelectField.new(
            name: :lectures,
            label: I18n.t("basics.lectures"),
            help_text: I18n.t("search.filters.helpdesks.lecture_scope_filter"),
            collection: lecture_options,
            form_state: form_state,
            **@options
          ).with_form(form)
        end

        def setup_radio_group
          setup_radio_buttons
          @radio_group_wrapper = Fields::Utilities::RadioGroupWrapper.new(
            name: :lecture_option,
            parent_field: @multi_select_field,
            radio_buttons: [@all_radio, @subscribed_radio, @own_selection_radio]
          )
        end

        def setup_radio_buttons
          @all_radio = Fields::RadioButtonField.new(
            name: :lecture_option,
            value: "0",
            label: I18n.t("search.radio_buttons.lecture_scope_filter.all"),
            checked: true,
            form_state: form_state,
            disabled: false,
            inline: false,
            container_class: "form-check",
            stimulus: { radio_toggle: true, controls_select: false }
          ).with_form(form)

          @subscribed_radio = Fields::RadioButtonField.new(
            name: :lecture_option,
            value: "1",
            label: I18n.t("search.radio_buttons.lecture_scope_filter.subscribed"),
            checked: false,
            form_state: form_state,
            disabled: false,
            inline: false,
            container_class: "form-check",
            stimulus: { radio_toggle: true, controls_select: false }
          ).with_form(form)

          @own_selection_radio = Fields::RadioButtonField.new(
            name: :lecture_option,
            value: "2",
            label: I18n.t("search.radio_buttons.lecture_scope_filter.own_selection"),
            checked: false,
            form_state: form_state,
            disabled: false,
            inline: false,
            container_class: "form-check",
            stimulus: { radio_toggle: true, controls_select: true }
          ).with_form(form)
        end

        # This private method is responsible for building the collection.
        # Its logic is described in the initialize method's documentation.
        def lecture_options
          Lecture.includes(:course, :term)
                 .map { |l| [l.title, l.id] }
                 .natural_sort_by(&:first)
        end
    end
  end
end
