# This service orchestrates the entire search process from within a controller.
# It uses a configurator to get the search setup, runs the search via the
# PaginatedSearcher, and returns a `PaginatedSearcher::SearchResult` object.
#
# The calling controller is then responsible for assigning the results to
# instance variables for the view.
#
# Example usage in a controller:
#
#   search_result = Search::Searchers::ControllerSearcher.search(...)
#   @courses = search_result.results
#   @total = search_result.total_count
#
# The calling controller is expected to implement a private `search_params` method
# that uses `params.permit` to permit the search form parameters.
module Search
  module Searchers
    class ControllerSearcher
      # @param controller [ApplicationController] The instance of the calling controller.
      # @param model_class [Class] The ActiveRecord model to be searched.
      # @param configurator_class [Class] The specific configurator for the model.
      # @param options [Hash] A hash of optional settings:
      #   - default_per_page [Integer]
      #   - params_method_name [Symbol] The method to call on the controller to get
      #     the permitted search parameters. Defaults to :search_params.
      # @return [Search::Searchers::SearchResult] An object containing the paginated
      #   results and the total count.
      def self.search(controller:, model_class:, configurator_class:, options: {})
        default_per_page = options.fetch(:default_per_page, 10)
        params_method_name = options.fetch(:params_method_name, :search_params)

        config = configurator_class.call(
          user: controller.current_user,
          search_params: permitted_controller_params(controller, params_method_name),
          cookies: controller.send(:cookies)
        )

        unless config
          return Searchers::SearchResult.new(results: model_class.none,
                                             total_count: 0)
        end

        PaginatedSearcher.search(
          model_class: model_class,
          user: controller.current_user,
          config: config,
          default_per_page: default_per_page
        )
      end

      class << self
        private

          # Gets the initial, permitted parameters by calling the specified method
          # on the controller, and then merges in the top-level :page parameter.
          def permitted_controller_params(controller, params_method_name)
            search_specific_params = controller.send(params_method_name)
            permitted_hash = search_specific_params.to_h
            permitted_hash[:page] = controller.params[:page] if controller.params.key?(:page)
            permitted_hash
          end
      end
    end
  end
end
