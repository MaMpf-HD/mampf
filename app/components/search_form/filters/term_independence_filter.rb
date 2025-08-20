# Provides a checkbox filter for term-independent courses in the search form.
# This component uses composition over inheritance by rendering a Checkbox control
# rather than inheriting from it. This design choice:
#   - Maintains proper separation of concerns (fields handle layout, controls handle inputs)
#   - Preserves the field structure with consistent column classes and container styling
#   - Keeps the component in the logical Filter hierarchy while leveraging a reusable control
# All filters in the system follow this pattern to ensure consistent UI structure
# while promoting reuse of the underlying control components.
module SearchForm
  module Filters
    class TermIndependenceFilter < Fields::Field
      def initialize(context: "course", **)
        super(
          name: :term_independent,
          label: I18n.t("admin.course.term_independent"),
          column_class: "col-6 col-lg-3",
          context: context,
          **
        )
      end

      def call
        render(Controls::Checkbox.new(
                 form: form,
                 context: context,
                 name: name,
                 label: label,
                 checked: false
               ))
      end
    end
  end
end
