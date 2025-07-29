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
    # Use the controller's context to get the current user and params.
    user = controller.current_user
    search_params = controller.send(:search_params)
    pagination_params = controller.params

    # 1. Get the configuration (filters and processed params).
    configurator = configurator_class.call(user: user, search_params: search_params)

    # 2. Build the config for the paginated searcher.
    config = ::PaginatedSearcher::SearchConfig.new(
      search_params: configurator.params,
      pagination_params: pagination_params,
      default_per_page: default_per_page
    )

    # 3. Run the search.
    search = ::PaginatedSearcher.call(model_class: model_class,
                                      filter_classes: configurator.filters,
                                      user: user,
                                      config: config)

    # 4. Set the instance variables on the controller for the view.
    controller.instance_variable_set(:@total, search.total_count)
    controller.instance_variable_set("@#{instance_variable_name}", search.results)
  end
end
