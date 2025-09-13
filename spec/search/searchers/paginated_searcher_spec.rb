require "rails_helper"

RSpec.describe(Search::Searchers::PaginatedSearcher) do
  # --- Test Doubles & Setup ---
  let(:user) { create(:user) }
  let(:model_class) { class_spy(Course, "ModelClass") }
  let(:search_results) { instance_spy(ActiveRecord::Relation, "SearchResults") }
  let(:paginated_scope) { double("PaginatedScope") }

  # Use a real Pagy object to ensure its internal logic is correctly handled.
  let!(:pagy_object) { Pagy.new(count: total_count, page: params[:page], limit: items_per_page) }
  let(:total_count) { 48 }

  let(:params) { { page: "2", per: "10" } }
  let(:items_per_page) { params[:per] || default_per_page }
  let(:config) do
    instance_double(
      Search::Configurators::Configuration,
      params: params
    )
  end
  let(:default_per_page) { 15 }

  subject(:search) do
    described_class.search(
      model_class: model_class,
      user: user,
      config: config,
      default_per_page: default_per_page
    )
  end

  before do
    subquery_scope = double("SubqueryScope")
    allow(model_class).to receive(:from).with(search_results,
                                              :subquery_for_count).and_return(subquery_scope)
    allow(subquery_scope).to receive(:count).and_return(total_count)

    allow(Search::Searchers::ModelSearcher).to receive(:search).and_return(search_results)
    allow(Pagy).to receive(:new).and_return(pagy_object)
    allow(search_results).to receive(:offset).with(pagy_object.offset).and_return(search_results)
    allow(search_results).to receive(:limit).with(pagy_object.limit).and_return(paginated_scope)
  end

  # --- Tests ---

  it "calls ModelSearcher to get the base results" do
    search
    expect(Search::Searchers::ModelSearcher).to have_received(:search)
  end

  it "returns a SearchResult struct with the pagy object and paginated results" do
    expect(search).to be_a(Search::Searchers::SearchResult)
    expect(search.pagy).to eq(pagy_object)
    expect(search.results).to eq(paginated_scope)
  end

  it "calculates the total count using a subquery" do
    search
    expect(model_class).to have_received(:from).with(search_results, :subquery_for_count)
  end

  it "paginates the results using offset and limit from the Pagy object" do
    search
    expect(search_results).to have_received(:offset).with(pagy_object.offset)
    expect(search_results).to have_received(:limit).with(pagy_object.limit)
  end

  describe "Pagy initialization" do
    it "initializes Pagy with the correct count and limit from params" do
      search
      expect(Pagy).to have_received(:new).with(
        count: total_count,
        limit: "10",
        page: "2"
      )
    end

    context "when 'per' is not in params" do
      let(:params) { { page: "2" } }
      let(:items_per_page) { default_per_page }

      it "uses the default_per_page value for limit" do
        search
        expect(Pagy).to have_received(:new).with(
          count: total_count,
          limit: default_per_page,
          page: "2"
        )
      end
    end

    context "when 'all' param is present" do
      let(:params) { { all: "1" } }
      let(:items_per_page) { total_count }

      it "initializes Pagy with 'limit' equal to the total count" do
        search
        expect(Pagy).to have_received(:new).with(
          count: total_count,
          limit: total_count,
          page: nil
        )
      end

      context "and the result set is empty" do
        let(:total_count) { 0 }
        let(:items_per_page) { 1 }

        it "uses a 'limit' value of 1 to avoid Pagy errors" do
          search
          expect(Pagy).to have_received(:new).with(
            count: 0,
            limit: 1,
            page: nil
          )
        end
      end
    end
  end
end
