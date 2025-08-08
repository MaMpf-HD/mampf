# This service orchestrates the entire search process from within a controller.
# It uses a configurator to get the search setup, runs the search via the
# PaginatedSearcher, and then sets two instance variables on the calling
# controller for the view:
#   - @total: The total number of unpaginated results.
#   - @<instance_variable_name>: The paginated array of results.
#
# The calling controller is expected to implement a private `search_params` method
# that uses `params.expect` to permit the search form parameters.
module Search
  module Searchers
    class ControllerSearcher
      # @param controller [ApplicationController] The instance of the calling controller.
      # @param model_class [Class] The ActiveRecord model to be searched.
      # @param configurator_class [Class] The specific configurator for the model.
      # @param instance_variable_name [Symbol] The name for the results instance variable.
      # @param options [Hash] A hash of optional settings:
      #   - default_per_page [Integer]
      #   - params_method_name [Symbol] The method to call on the controller to get
      #     the permitted search parameters. Defaults to :search_params.
      def self.call(controller:, model_class:, configurator_class:, instance_variable_name:,
                    options: {})
        new(controller: controller, model_class: model_class,
            configurator_class: configurator_class,
            instance_variable_name: instance_variable_name,
            options: options).call
      end

      attr_reader :controller, :model_class, :configurator_class,
                  :instance_variable_name, :default_per_page, :params_method_name

      def initialize(controller:, model_class:, configurator_class:, instance_variable_name:,
                     options:)
        @controller = controller
        @model_class = model_class
        @configurator_class = configurator_class
        @instance_variable_name = instance_variable_name
        @default_per_page = options.fetch(:default_per_page, 10)
        @params_method_name = options.fetch(:params_method_name, :search_params)
      end

      def call
        # Get the search configuration. The `config.params` becomes the
        # single source of truth from this point forward.
        config = configurator_class.call(user: controller.current_user,
                                         search_params: permitted_controller_params)

        # If the configurator returns nil (e.g., required lecture not found),
        # set empty results and stop.
        unless config
          return assign_results_to_controller(
            PaginatedSearcher::SearchResult.new(results: model_class.none, total_count: 0)
          )
        end

        # Execute the search using the configuration.
        search_result = execute_paginated_search(config)

        # Assign the results to instance variables on the controller.
        assign_results_to_controller(search_result)
      end

      private

        # Executes the search using the PaginatedSearcher.
        # @param search_config [Configurators::BaseSearchConfigurator::Configuration]
        #   The configuration from the model's configurator. This is the single
        #   source of truth for all parameters.
        # @return [PaginatedSearcher::SearchResult]
        def execute_paginated_search(search_config)
          # Extract all pagination-related parameters from the authoritative config.
          pagination_params = search_config.params.slice(:page, :per)
          all_param = search_config.params[:all]

          paginated_search_config = PaginatedSearcher::SearchConfig.new(
            search_params: search_config.params,
            pagination_params: pagination_params,
            default_per_page: default_per_page,
            orderer_class: search_config.orderer_class,
            all: all_param
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

        # Gets the initial, permitted parameters by calling the specified method
        # on the controller.
        def permitted_controller_params
          controller.send(params_method_name)
        end
    end
  end
end
