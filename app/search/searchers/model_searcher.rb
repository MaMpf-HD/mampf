# Orchestrates the process of building a complex, filterable,  and sortable
# database query for a given model. It uses a set of filter classes to apply
# various conditions and then ensures the results are unique and correctly sorted.
module Search
  module Searchers
    class ModelSearcher
      # @param model_class [Class] The ActiveRecord model class to be searched.
      # @param user [User] The current user, for permission-sensitive filters.
      # @param config [Configurators::Configuration]
      #   The configuration object from the model's configurator.
      # @return [ActiveRecord::Relation] The resulting query object.
      def self.search(model_class:, user:, config:)
        sorter_class = config.sorter_class || Sorters::SearchSorter

        scope = Filters::FilterApplier.apply(scope: model_class.all,
                                             user: user,
                                             config: config)

        scope = scope.distinct

        sorter_class.sort(model_class: model_class,
                          scope: scope,
                          search_params: config.params)
      end
    end
  end
end
