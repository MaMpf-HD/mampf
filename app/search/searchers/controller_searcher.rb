# Orchestrates the entire search process from within a controller.
# It uses a configurator to get the search setup, then uses the Pagy
# countish paginator to return paginated results.
#
# The calling controller is then responsible for assigning the results to
# instance variables for the view.
#
# Example usage in a controller:
#
#   @pagy, @results = Search::Searchers::ControllerSearcher.search(...)
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
      # @return [Array<Pagy, ActiveRecord::Relation>] A tuple containing the pagy
      #   object and the paginated collection of results
      def self.search(controller:, model_class:, configurator_class:, options: {})
        default_per_page = options.fetch(:default_per_page, 10)
        params_method_name = options.fetch(:params_method_name, :search_params)
        use_keynav = options.fetch(:use_keynav, false)

        config = configurator_class.configure(
          user: controller.current_user,
          search_params: permitted_controller_params(controller, params_method_name),
          cookies: controller.send(:cookies)
        )

        return controller.send(:pagy, :countish, model_class.none, limit: 1, page: 1) unless config

        search_results = ModelSearcher.search(
          model_class: model_class,
          user: controller.current_user,
          config: config
        )

        items_per_page = calculate_items_per_page(config, model_class, search_results,
                                                  default_per_page)

        if use_keynav
          # keyset/keynav_js require simple column-based ordering
          # Override the complex search order with a simple id-based order
          # TODO: think of better ordering
          search_results = search_results.reorder(id: :asc)
          controller.send(:pagy, :keyset, search_results, limit: items_per_page)
        else
          controller.send(:pagy, :countish, search_results,
                          limit: items_per_page, page: config.params[:page])
        end
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

          def calculate_items_per_page(config, model_class, search_results, default_per_page)
            if config.params[:all]
              # To get an accurate count from a query that might contain DISTINCT or
              # GROUP BY clauses, we wrap the original query in a subquery and
              # count the results of that.
              correct_count = model_class.from(search_results, :subquery_for_count).count
              # Use a minimum of 1 to avoid Pagy errors if the count is 0
              [correct_count, 1].max
            else
              config.params[:per] || default_per_page
            end
          end
      end
    end
  end
end
