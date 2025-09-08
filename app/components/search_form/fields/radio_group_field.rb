module SearchForm
  module Fields
    class RadioGroupField < Field
      # Use class-based slot; pass all needed args explicitly from the template
      renders_many :radio_buttons, "SearchForm::Fields::RadioButtonField"

      def initialize(name:, label: nil, **)
        super(name: name, label: label || "", **)
      end

      def render_in(view_context, &block)
        Rails.logger.warn("RGF render_in: block_given?=#{!block.nil?}")
        super.tap do
          Rails.logger.warn("RGF after render_in: slots=#{radio_buttons.size} content?=#{defined?(content) && content.present?}")
        end
      end

      def with_radio_button(*args, **kwargs, &)
        Rails.logger.warn("RGF with_radio_button called kwargs=#{kwargs.inspect}")
        super
      end

      def before_render
        pp("#######################################")
        Rails.logger.warn("RadioGroupField: slots=#{radio_buttons.size} content?=#{respond_to?(:content) && content.present?}")
      end

      def default_container_class
        "col-6 col-lg-3 mb-3 form-field-group"
      end

      def default_field_classes
        []
      end
    end
  end
end
