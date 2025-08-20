# app/components/search_form/controls/radio_group.rb
module SearchForm
  module Controls
    class RadioGroup < BaseControl
      attr_reader :name

      renders_many :radio_buttons, RadioButton

      def initialize(form_state:, name:, **)
        super(form_state: form_state, **)
        @name = name
      end

      # Override the default container class
      def default_container_class
        "mt-2"
      end

      private

        # RadioGroup uses just the name for its ID
        def id_parts
          [name]
        end
    end
  end
end
