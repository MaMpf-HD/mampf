require "rails_helper"

RSpec.describe(Search::Configurators::LectureSearchConfigurator) do
  describe "#call" do
    it "returns a configuration with the correct set of filters" do
      user = create(:user)
      search_params = { fulltext: "Calculus" }

      # Instantiate and call the configurator
      configuration = described_class.configure(user: user, search_params: search_params)

      # Define the expected list of filters
      expected_filters = [
        Search::Filters::TypeFilter,
        Search::Filters::TermFilter,
        Search::Filters::ProgramFilter,
        Search::Filters::TeacherFilter,
        Search::Filters::LectureVisibilityFilter,
        Search::Filters::FulltextFilter
      ]

      # This is the single, most important expectation for this class.
      expect(configuration.filters).to match_array(expected_filters)
    end
  end
end
