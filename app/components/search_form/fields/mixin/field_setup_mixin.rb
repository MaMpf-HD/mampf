module SearchForm
  module Fields
    module Mixin
      # Very lightweight mixin for common field setup patterns
      module FieldSetupMixin
        def self.included(base)
          base.attr_accessor(:form_state)
          base.delegate(:form, to: :form_state)
        end

        def with_form(form)
          form_state.with_form(form)
          self
        end

        def before_render
          setup_fields
        end

        protected

          # Helper to create multi-select fields with consistent patterns
          def create_multi_select_field(**config)
            Fields::Primitives::MultiSelectField.new(
              form_state: form_state,
              **config
            ).with_form(form)
          end

          # Helper to create "All" checkboxes with consistent patterns
          def create_all_checkbox(for_field_name:, **extra_config)
            base_name = for_field_name.to_s.delete_suffix("_ids").pluralize
            all_name = :"all_#{base_name}"

            Fields::Primitives::CheckboxField.new(
              name: all_name,
              label: I18n.t("basics.all"),
              checked: true,
              form_state: form_state,
              container_class: "form-check mb-2",
              stimulus: { toggle: true },
              **extra_config
            ).with_form(form)
          end

          # Helper to create text fields
          def create_text_field(**config)
            Fields::Primitives::TextField.new(
              form_state: form_state,
              **config
            ).with_form(form)
          end

          # Helper to create select fields
          def create_select_field(**config)
            Fields::Primitives::SelectField.new(
              form_state: form_state,
              **config
            ).with_form(form)
          end

          # Helper to create radio button fields
          def create_radio_button_field(**config)
            Fields::Primitives::RadioButtonField.new(
              form_state: form_state,
              **config
            ).with_form(form)
          end

          # Helper to create checkbox fields
          def create_checkbox_field(**config)
            Fields::Primitives::CheckboxField.new(
              form_state: form_state,
              **config
            ).with_form(form)
          end

          # Must be implemented by including class
          def setup_fields
            raise(NotImplementedError, "#{self.class.name} must implement #setup_fields")
          end
      end
    end
  end
end
