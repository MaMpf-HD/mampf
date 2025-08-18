module SearchForm
  module Filters
    class TermIndependenceFilterComponent < SearchForm::Field
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
        render(SearchForm::Controls::Checkbox.new(
                 form: form,
                 name: name,
                 label: label,
                 checked: false
               ))
      end
    end
  end
end
