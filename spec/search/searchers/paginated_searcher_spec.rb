require "rails_helper"

RSpec.describe(Search::Searchers::PaginatedSearcher) do
  let(:user) { create(:user) }
  let(:model_class) { class_spy(Course, "ModelClass") }
  let(:search_results) { instance_spy(ActiveRecord::Relation, "SearchResults") }
  let(:paginated_scope) { double("PaginatedScope") }
  let(:pagy_object) { instance_double(Pagy, offset: 20, vars: { items: 10 }, count: 48) }

  let(:params) { { page: "2", per: "10" } }
  let(:config) do
    instance_double(
      Search::Configurators::BaseSearchConfigurator::Configuration,
      params: params
    )
  end

  let(:default_per_page) { 15 }

  subject(:search) do
    described_class.call(
      model_class: model_class,
      user: user,
      config: config,
      default_per_page: default_per_page
    )
  end

  before do
    allow(Search::Searchers::ModelSearcher).to receive(:call).and_return(search_results)
    allow(model_class).to receive(:from).and_return(model_class)
    allow(model_class).to receive(:count).and_return(48)
    allow(Pagy).to receive(:new).and_return(pagy_object)
    allow(search_results).to receive(:offset).and_return(search_results)
    allow(search_results).to receive(:limit).and_return(paginated_scope)
  end

  it "calls ModelSearcher to get the base results" do
    search
    expect(Search::Searchers::ModelSearcher).to have_received(:call)
  end

  it "returns a SearchResult struct with pagy object and results" do
    expect(search.pagy).to eq(pagy_object)
    expect(search.results).to eq(paginated_scope)
  end

  describe "count calculation" do
    it "calculates the total count using a subquery" do
      search
      expect(model_class).to have_received(:from).with(search_results, :subquery_for_count)
      expect(model_class).to have_received(:count)
    end
  end

  describe "pagination logic" do
    it "initializes Pagy with correct arguments" do
      search
      expect(Pagy).to have_received(:new).with(
        count: 48,
        items: "10",
        limit: "10",
        page: "2"
      )
    end

    it "paginates the results using offset and limit from Pagy" do
      search
      expect(search_results).to have_received(:offset).with(pagy_object.offset)
      expect(search_results).to have_received(:limit).with(pagy_object.vars[:items])
    end

    context "when 'per' is not in params" do
      let(:params) { { page: "2" } }

      it "uses the default_per_page value for items" do
        search
        expect(Pagy).to have_received(:new).with(
          count: 48,
          items: default_per_page,
          limit: default_per_page,
          page: "2"
        )
      end
    end

    context "when 'all' param is present" do
      let(:params) { { all: "1" } }

      before do
        allow(search_results).to receive(:count).and_return(5)
      end

      it "uses the total count for items" do
        search
        expect(Pagy).to have_received(:new).with(
          count: 48,
          items: 5,
          limit: 5,
          page: nil
        )
      end
    end
  end
end
