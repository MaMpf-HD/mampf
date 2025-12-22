# Mampf Search Architecture

This document explains the architecture of the `Search` module, which handles all database queries related to searches in the application.


## Core Concepts

The search system is composed of several types of service objects, each with a specific role.

### Searchers (`app/search/searchers/`)

Searchers are the orchestrators that manage the overall search lifecycle.

- `ControllerSearcher`: The main entry point called from a controller. It coordinates with the configurator and uses Pagy for pagination.
- `ModelSearcher`: The core query engine. It applies all filters and sorters to build the final `ActiveRecord::Relation`.

### Configurators (`app/search/configurators/`)

Configurators are the "recipe" providers for a search. Each searchable model has its own configurator (e.g., `MediaSearchConfigurator`). Its job is to define:

- Which `Filter` classes to apply.
- Whether a custom `Sorter` is needed for complex ordering.
- Any pre-processing logic for the raw search parameters.

### Filters (`app/search/filters/`)

Filters are responsible for applying one specific condition to a search query (e.g., a `WHERE` clause). They are the fundamental, reusable building blocks of the system.

- All filters inherit from `BaseFilter`.
- The core logic is implemented in the `#filter` method.
- `BaseFilter` provides a `skip_filter?` helper for common guard clauses.

### Sorters (`app/search/sorters/`)

Sorters are responsible for applying an `ORDER BY` clause to the query.

- `BaseSorter`: Provides common functionality, like handling the `reverse` parameter.
- `SearchSorter`: The default sorter. It intelligently sorts by full-text relevance or the model's default order.
- Custom Sorters (e.g., `LectureMediaSorter`): Can be created for highly complex sorting scenarios that require custom Arel logic.

### Parsers (`app/search/parsers/`)

Parsers are optional helper services that can be used by a `Configurator` to pre-process complex search parameters before they are passed to the filters. For example, `TeachableParser` expands a list of teachable identifiers to include their children when inheritance is needed.

## Data Flow

A typical search request flows through the system as follows:

```
[Controller Action]
       |
       v
[Search::Searchers::ControllerSearcher]  (Entry point)
       |
       |--- calls ---> [Search::Configurators::*] (Gets the "recipe": filters, sorter)
       |
       |--- calls ---> [Search::Searchers::ModelSearcher] (The query engine)
       |                  |
       |                  |--- applies ---> [Search::Filters::*] (Builds WHERE clauses)
       |                  |
       |                  '--- applies ---> [Search::Sorters::*] (Builds ORDER BY clause)
       |
       |--- calls ---> [controller.pagy(:countish, ...)] (Pagy 43 pagination)
       |
       v
[Tuple: @pagy, @records] (Returns paginated results to controller)
```

## How-To Guides

### How to Make a New Model Searchable

1. **Create a Configurator.** In `app/search/configurators/`, create a new class for your model (e.g., `UserSearchConfigurator < BaseSearchConfigurator`).
2. **Define Filters.** In your new configurator, implement the `filters` method to return an array of the `Filter` classes you need.

    ```ruby
    def filters
      [
        Filters::FulltextFilter,
        Filters::CustomUserFilter # etc.
      ]
    end
    ```

3. **Call the Searcher.** In your controller action (e.g., `UsersController#index`), call the `ControllerSearcher`.

    ```ruby
    @pagy, @users = Search::Searchers::ControllerSearcher.search(
      controller: self,
      model_class: User,
      configurator_class: Search::Configurators::UserSearchConfigurator
    )
    ```

4. **Permit Parameters.** Ensure your controller has a `private` method (usually `search_params`) that permits all the parameters your filters will use.

### How to Add a New Filter to an Existing Search

1. **Create the Filter Class.** In `app/search/filters/`, create your new filter class, inheriting from `BaseFilter`. Implement the `#filter` method.

    ```ruby
    # app/search/filters/user_status_filter.rb
    class UserStatusFilter < BaseFilter
      def filter
        return scope if params[:status].blank? # also consider using skip_filter?()
        scope.where(status: params[:status])
      end
    end
    ```

2. **Add to Configurator.** Add your new `Filters::UserStatusFilter` to the `filters` array in the relevant configurator (e.g., `UserSearchConfigurator`).

3. **Permit the Parameter.** Add `:status` (in this example) to the `permit` list in the controller's `search_params` method.
