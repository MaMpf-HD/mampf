module SearchForm
  module Builders
    class FormBuilder
      def initialize(form_state)
        @form_state = form_state
        @filter_manager = FilterManager.new(form_state)
        @fields = []
        @hidden_fields = []
      end

      # Dynamically define ALL filter methods from registry
      FilterRegistry.all_filters.each do |filter_name, config|
        define_method "#{filter_name}_filter" do |**options|
          if FilterRegistry.complex_filter?(filter_name)
            builder = @filter_manager.create_dynamic_filter_builder(filter_name, config, **options)
            @fields << builder.build
            builder
          else
            merged_options = (config[:defaults] || {}).merge(options)
            filter = @filter_manager.build_simple_filter(filter_name, **merged_options)
            @fields << filter
            filter
          end
        end
      end

      def hidden_field(**fields)
        fields.each do |name, value|
          @hidden_fields << { name: name, value: value }
        end
        self
      end

      def build_form(url:, **form_options)
        SearchForm.new(url: url, **form_options).tap do |form|
          @fields.each { |field| form.with_field(field) }
          @hidden_fields.each { |hf| form.with_hidden_field(name: hf[:name], value: hf[:value]) }
        end
      end

      private

        attr_reader :filter_manager
    end
  end
end
