class MediaSearchConfigurator
  Configuration = Struct.new(:filters, :params, keyword_init: true)

  # Returns the list of filters and processed parameters for a media search.
  #
  # @param user [User] The current user.
  # @param search_params [Hash] The search parameters.
  # @return [Configuration] An object containing the filter classes and params.
  def self.call(user:, search_params:)
    new(user: user, search_params: search_params).call
  end

  attr_reader :user, :search_params

  def initialize(user:, search_params:)
    @user = user
    @search_params = search_params.to_h.with_indifferent_access
  end

  def call
    Configuration.new(
      filters: build_filters,
      params: process_params
    )
  end

  private

    def build_filters
      [
        ::Filters::ProperFilter,
        ::Filters::TypeFilter,
        ::Filters::TeachableFilter,
        ::Filters::TagFilter,
        ::Filters::EditorFilter,
        ::Filters::AnswerCountFilter,
        ::Filters::LectureScopeFilter,
        ::Filters::FulltextFilter
      ] + visibility_filters
    end

    def visibility_filters
      if user.active_teachable_editor?
        [::Filters::MediumAccessFilter]
      else
        [::Filters::MediumVisibilityFilter]
      end
    end

    def process_params
      processed = search_params.deep_dup

      # Remove the :access parameter if the user is not an editor, as the
      # MediumVisibilityFilter does not use it.
      processed.delete(:access) unless user.active_teachable_editor?

      # If "all types" is selected from the start page search, we default to
      # searching within all generic media types.
      if processed[:all_types] == "1" && processed[:from] == "start"
        processed[:types] = Medium.generic_sorts
      end

      processed
    end
end
