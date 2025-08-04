# This service orchestrates the entire search process from within a controller.
# It uses a configurator to get the search setup, runs the search via the
# PaginatedSearcher, and then sets two instance variables on the calling
# controller for the view:
#   - @total: The total number of unpaginated results.
#   - @<instance_variable_name>: The paginated array of results.
class ControllerSearcher
  # @param controller [ApplicationController] The instance of the calling controller.
  # @param model_class [Class] The ActiveRecord model to be searched.
  # @param configurator_class [Class] The specific configurator for the model.
  # @param instance_variable_name [Symbol] The name for the results instance variable.
  # @param default_per_page [Integer] The default number of items per page.
  def self.call(controller:, model_class:, configurator_class:, instance_variable_name:,
                default_per_page: 10)
    new(controller: controller, model_class: model_class,
        configurator_class: configurator_class,
        instance_variable_name: instance_variable_name,
        default_per_page: default_per_page).call
  end

  attr_reader :controller, :model_class, :configurator_class,
              :instance_variable_name, :default_per_page

  def initialize(controller:, model_class:, configurator_class:, instance_variable_name:,
                 default_per_page:)
    @controller = controller
    @model_class = model_class
    @configurator_class = configurator_class
    @instance_variable_name = instance_variable_name
    @default_per_page = default_per_page
  end

  def call
    config = search_configuration
    search_result = execute_paginated_search(config)
    assign_results_to_controller(search_result)
  end

  private

    # Calls the specific configurator class to get the list of filters
    # and the processed search parameters.
    # @return [Configurators::BaseSearchConfigurator::Configuration]
    def search_configuration
      configurator_class.call(user: controller.current_user,
                              search_params: controller.send(:search_params))
    end

    # Executes the search using the PaginatedSearcher.
    # @param search_config [Configurators::BaseSearchConfigurator::Configuration]
    # @return [PaginatedSearcher::SearchResult]
    def execute_paginated_search(search_config)
      paginated_search_config = ::PaginatedSearcher::SearchConfig.new(
        search_params: search_config.params,
        pagination_params: controller.params,
        default_per_page: default_per_page
      )

      ::PaginatedSearcher.call(
        model_class: model_class,
        filter_classes: search_config.filters,
        user: controller.current_user,
        config: paginated_search_config
      )
    end

    # Sets the final instance variables on the controller for the view.
    # @param search_result [PaginatedSearcher::SearchResult]
    def assign_results_to_controller(search_result)
      controller.instance_variable_set(:@total, search_result.total_count)
      controller.instance_variable_set("@#{instance_variable_name}",
                                       search_result.results)
    end
end
