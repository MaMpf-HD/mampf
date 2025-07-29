class LectureSearchConfigurator
  Configuration = Struct.new(:filters, :params, keyword_init: true)
  # Returns the list of filters required for a lecture search.
  #
  # @param user [User] The current user.
  # @param search_params [Hash] The search parameters.
  # @return [OpenStruct] An object containing the filter classes and params.
  def self.call(user:, search_params:)
    new(user: user, search_params: search_params).call
  end

  attr_reader :user, :search_params

  def initialize(user:, search_params:)
    @user = user
    @search_params = search_params
  end

  def call
    Configuration.new(
      filters: [
        ::Filters::LectureTypeFilter,
        ::Filters::TermFilter,
        ::Filters::ProgramFilter,
        ::Filters::TeacherFilter,
        ::Filters::LectureVisibilityFilter,
        ::Filters::FulltextFilter
      ],
      params: search_params
    )
  end
end
