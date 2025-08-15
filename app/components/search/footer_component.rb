module Search
  class FooterComponent < ViewComponent::Base
    attr_reader :results_container_id, :extra_classes

    def initialize(results_container_id:, extra_classes: "")
      super()
      @results_container_id = results_container_id
      @extra_classes = extra_classes
    end
  end
end
