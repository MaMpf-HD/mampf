require "rails_helper"

RSpec.describe(Search::Configurators::CourseSearchConfigurator) do
  describe "#call" do
    it "returns a configuration with the correct set of filters" do
      user = create(:user)
      search_params = { fulltext: "Ruby" }

      # Instantiate and call the configurator
      configuration = described_class.configure(user: user, search_params: search_params)

      # Define the expected list of filters
      expected_filters = [
        Search::Filters::EditorFilter,
        Search::Filters::ProgramFilter,
        Search::Filters::TermIndependenceFilter,
        Search::Filters::FulltextFilter
      ]

      # This is the single, most important expectation for this class.
      expect(configuration.filters).to match_array(expected_filters)
    end
  end
end
