module Search
  class TextFieldComponent < FormFieldComponent
    def initialize(name:, label:, column_class: "col-4", **)
      super
    end

    protected

      def process_options(options)
        options.reverse_merge(class: "form-control")
      end
  end
end
