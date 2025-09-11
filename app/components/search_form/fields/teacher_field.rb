module SearchForm
  module Fields
    class TeacherField < ViewComponent::Base
      include Mixin::FieldSetupMixin

      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
      end

      private

        def setup_fields
          # Very explicit - you can see exactly what's happening
          @multi_select_field = create_multi_select_field(
            name: :teacher_ids,
            label: I18n.t("basics.teachers"),
            help_text: I18n.t("search.filters.helpdesks.teacher_filter"),
            collection: User.select_teachers,
            **@options
          )

          @all_checkbox = create_all_checkbox(for_field_name: :teacher_ids)

          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end
    end
  end
end
