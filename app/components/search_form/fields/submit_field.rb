module SearchForm
  module Fields
    class SubmitField < Field
      attr_reader :button_class, :inner_class

      def initialize(label: nil, button_class: "btn btn-primary",
                     container_class: "row mb-3", inner_class: "col-12 text-center", **)
        super(name: :submit, label: label || I18n.t("basics.search"),
              container_class: container_class, **)
        @button_class = button_class
        @inner_class = inner_class
      end
    end
  end
end
