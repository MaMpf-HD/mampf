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
        # Get the search configuration from the configurator.
        config = configurator_class.call(user: controller.current_user,
                                         search_params: permitted_controller_params,
                                         cookies: controller.send(:cookies))

        # If the configurator returns nil (e.g., required lecture not found),
        # set empty results and stop.
        unless config
          return assign_results_to_controller(
            PaginatedSearcher::SearchResult.new(results: model_class.none, total_count: 0)
          )
        end

        # Execute the search by passing the config directly.
        search_result = PaginatedSearcher.call(
          model_class: model_class,
          user: controller.current_user,
          config: config,
          default_per_page: default_per_page
        )

        # 3. Assign the results to instance variables on the controller.
        assign_results_to_controller(search_result)
      end

      private

        # Sets the final instance variables on the controller for the view.
        # @param search_result [PaginatedSearcher::SearchResult]
        def assign_results_to_controller(search_result)
          controller.instance_variable_set(:@total, search_result.total_count)
          controller.instance_variable_set("@#{instance_variable_name}",
                                           search_result.results)
        end

        # Gets the initial, permitted parameters by calling the specified method
        # on the controller, and then merges in the top-level :page parameter.
        def permitted_controller_params
          # Get the search-specific parameters (e.g., from params[:search]).
          # This hash should contain any nested pagination params like :per.
          search_specific_params = controller.send(params_method_name)

          # Convert to a plain hash to ensure we can safely manipulate it.
          permitted_hash = search_specific_params.to_h

          # If a top-level :page parameter exists, explicitly set it on our hash.
          # This ensures it is always the authoritative value for pagination,
          # overwriting any nested :page parameter if one existed.
          permitted_hash[:page] = controller.params[:page] if controller.params.key?(:page)

          permitted_hash
        end
    end
  end
end
