module SearchForm
  module Builders
    module RadioGroupFactories
      class Base
        def self.build(form_state, **options)
          raise(NotImplementedError, "Subclasses must implement build method")
        end

        def self.create_builder(form_state, name)
          RadioGroupBuilder.new(form_state, name)
        end
      end
    end
  end
end
