module SearchForm
  module Fields
    class TagField < ViewComponent::Base
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
          setup_checkbox_group
          setup_radio_group
        end

        def setup_multi_select_field
          @multi_select_field = Fields::Primitives::MultiSelectField.new(
            name: :tag_ids,
            label: I18n.t("basics.tags"),
            help_text: I18n.t("search.filters.helpdesks.tag_filter"),
            collection: [],
            form_state: form_state,
            data: {
              filled: false,
              ajax: true,
              model: "tag",
              locale: I18n.locale,
              placeholder: I18n.t("basics.select"),
              no_results: I18n.t("basics.no_results")
            }
          ).with_form(form)
        end

        def setup_checkbox_group
          setup_checkboxes
          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end

        def setup_checkboxes
          @all_checkbox = Fields::Primitives::CheckboxField.new(
            name: generate_all_toggle_name(:tag_ids),
            label: I18n.t("basics.all"),
            checked: true,
            form_state: form_state,
            container_class: "form-check mb-2",
            stimulus: {
              toggle: true,
              toggle_radio_group: "tag_operator",
              default_radio_value: "or"
            }
          ).with_form(form)
        end

        def setup_radio_group
          setup_radio_buttons
          @radio_group_wrapper = Fields::Utilities::RadioGroupWrapper.new(
            name: :tag_operator,
            parent_field: @multi_select_field,
            radio_buttons: [@or_radio_button, @and_radio_button]
          )
        end

        def setup_radio_buttons
          @or_radio_button = Fields::Primitives::RadioButtonField.new(
            name: :tag_operator,
            value: "or",
            label: I18n.t("basics.OR"),
            checked: true,
            form_state: form_state,
            disabled: true,
            inline: true,
            container_class: "form-check form-check-inline",
            stimulus: { radio_toggle: true, controls_select: false }
          ).with_form(form)

          @and_radio_button = Fields::Primitives::RadioButtonField.new(
            name: :tag_operator,
            value: "and",
            label: I18n.t("basics.AND"),
            checked: false,
            form_state: form_state,
            disabled: true,
            inline: true,
            container_class: "form-check form-check-inline",
            stimulus: { radio_toggle: true, controls_select: false }
          ).with_form(form)
        end

        def generate_all_toggle_name(name)
          base_name = name.to_s.delete_suffix("_ids").pluralize
          :"all_#{base_name}"
        end
    end
  end
end
