module SearchForm
  module Fields
    class SubmitField < Field
      attr_reader :css_classes, :wrapper_classes, :column_classes

      def initialize(label: nil, css_classes: "btn btn-primary",
                     wrapper_classes: "row mb-3", column_classes: "col-12 text-center", **)
        super(name: :submit, label: label || I18n.t("basics.search"), **)
        @css_classes = css_classes
        @wrapper_classes = wrapper_classes
        @column_classes = column_classes
      end

      def with_form(form)
        @form = form
        self
      end

      # Helper methods for common configurations
      def without_wrapper
        @wrapper_classes = nil
        @column_classes = nil
        self
      end

      def with_wrapper_classes(classes)
        @wrapper_classes = classes
        self
      end

      def with_column_classes(classes)
        @column_classes = classes
        self
      end

      private

        attr_reader :form
    end
  end
end
