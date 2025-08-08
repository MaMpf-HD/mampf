require "rails_helper"

RSpec.describe(Search::Configurators::LectureMediaSearchConfigurator) do
  describe ".call" do
    let(:user) { create(:user) }
    let(:lecture) { create(:lecture) }
    let(:search_params) { { id: lecture.id } }

    subject(:configuration) do
      described_class.call(user: user, search_params: search_params)
    end

    it "returns a configuration with the correct set of filters" do
      expected_filters = [
        Search::Filters::LectureMediaScopeFilter,
        Search::Filters::ImportedMediaFilter,
        Search::Filters::LectureMediaVisibilityFilter,
        Search::Filters::MediumVisibilityFilter
      ]
      expect(configuration.filters).to match_array(expected_filters)
    end

    it "returns a configuration with the correct orderer class" do
      expect(configuration.orderer_class).to eq(Search::Orderers::LectureMediaOrderer)
    end
  end
end
