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
      end

      delegate :form, to: :form_state

      def with_form(form)
        form_state.with_form(form)
        self
      end

      def before_render
        setup_fields
      end

      private

        def setup_fields
          setup_multi_select_field
          setup_radio_group
        end

        def setup_multi_select_field
          @multi_select_field = Fields::Primitives::MultiSelectField.new(
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
          @all_radio = Fields::Primitives::RadioButtonField.new(
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

          @subscribed_radio = Fields::Primitives::RadioButtonField.new(
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

          @own_selection_radio = Fields::Primitives::RadioButtonField.new(
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
