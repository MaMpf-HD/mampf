# This service orchestrates the entire search process from within a controller.
# It uses a configurator to get the search setup, runs the search via the
# PaginatedSearcher, and then sets two instance variables on the calling
# controller for the view:
#   - @total: The total number of unpaginated results.
#   - @<instance_variable_name>: The paginated array of results.
#
# The calling controller is expected to implement a private `search_params` method
# that uses `params.expect` to permit the search form parameters.module Search
module Search
  class ControllerSearcher
    # @param controller [ApplicationController] The instance of the calling controller.
    #   Must implement a private `search_params` method.
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
      # This holds the fully permitted search parameters object.
      permitted_search_params = controller.send(:search_params)

      # Pass the full object to the configurator. The configurator can
      # decide to do further processing if needed.
      config = configurator_class.call(user: controller.current_user,
                                       search_params: permitted_search_params)

      # Pass the permitted object to the paginated search as well.
      search_result = execute_paginated_search(config, permitted_search_params)
      assign_results_to_controller(search_result)
    end

    private

      # Executes the search using the PaginatedSearcher.
      # @param search_config [Configurators::BaseSearchConfigurator::Configuration]
      # The configuration from the model's configurator.
      # @param permitted_search_params [ActionController::Parameters]
      # The permitted parameters from the search form.
      # @return [PaginatedSearcher::SearchResult]
      def execute_paginated_search(search_config, permitted_search_params)
        # Assemble the pagination_params from their split sources.
        # Get :page from the top-level params.
        page_param = controller.params.slice(:page)
        # Get :per from the permitted search params object.
        per_param = permitted_search_params.slice(:per)
        # Merge them into a single, clean hash.
        pagination_params = page_param.merge(per_param)

        paginated_search_config = PaginatedSearcher::SearchConfig.new(
          # IMPORTANT: Use the params from the configurator's result,
          # as it may have processed them (e.g., MediaSearchConfigurator).
          search_params: search_config.params,
          pagination_params: pagination_params,
          default_per_page: default_per_page,
          orderer_class: search_config.orderer_class
        )

        PaginatedSearcher.call(
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
end
