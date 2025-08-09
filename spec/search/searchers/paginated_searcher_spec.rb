require "rails_helper"

RSpec.describe(Search::Searchers::PaginatedSearcher) do
  # Define spies and doubles for dependencies
  let(:user) { create(:user) }
  let(:model_class) { class_spy(Course, "ModelClass") }
  let(:search_results) { instance_spy(ActiveRecord::Relation, "SearchResults") }
  let(:paginatable_array) { instance_spy(Kaminari::PaginatableArray, "PaginatableArray") }
  # Use a simple 'double' for the page_scope, as its class is a Kaminari internal.
  let(:page_scope) { double("PageScope") }
  let(:paginated_scope) { double("PaginatedScope") }

  # Set up a double for the configuration object
  let(:params) { { page: "2", per: "20" } }
  let(:config) do
    instance_double(
      Search::Configurators::BaseSearchConfigurator::Configuration,
      params: params
    )
  end

  # Default arguments for the service call
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
    # Stub the main dependencies, correctly modeling the Kaminari chain.
    allow(Search::Searchers::ModelSearcher).to receive(:call).and_return(search_results)
    allow(Kaminari).to receive(:paginate_array).and_return(paginatable_array)
    # .page is called on paginatable_array and returns our new page_scope double
    allow(paginatable_array).to receive(:page).and_return(page_scope)
    # .per is called on the page_scope double
    allow(page_scope).to receive(:per).and_return(paginated_scope)
  end

  it "calls the ModelSearcher to get the base results" do
    search
    expect(Search::Searchers::ModelSearcher).to have_received(:call).with(
      model_class: model_class,
      user: user,
      config: config
    )
  end

  it "returns a SearchResult struct" do
    expect(search).to be_a(Search::Searchers::PaginatedSearcher::SearchResult)
    expect(search.results).to eq(paginated_scope)
  end

  describe "count calculation" do
    context "when the scope is a standard ActiveRecord::Relation" do
      it "calculates the total count using an efficient query" do
        allow(search_results).to receive(:group_values).and_return([])
        allow(search_results).to receive(:select).with(:id).and_return(search_results)
        search
        expect(search_results).to have_received(:count)
      end
    end

    context "when the scope has group_values" do
      it "calculates the count using a subquery" do
        allow(search_results).to receive(:group_values).and_return(["some_column"])
        allow(model_class).to receive(:from).and_return(model_class)
        allow(model_class).to receive(:count)
        search
        expect(model_class).to have_received(:from).with(search_results, :subquery)
        expect(model_class).to have_received(:count)
      end
    end

    context "when the scope is an Array" do
      let(:search_results) { [1, 2, 3] } # Override with a real array

      it "calculates the count using Array#size" do
        expect(search.total_count).to eq(3)
      end
    end
  end

  describe "pagination logic" do
    before do
      # For pagination tests, we need a real array and a real count
      allow(search_results).to receive(:to_a).and_return([1, 2, 3, 4, 5])
      allow(search_results).to receive(:group_values).and_return([])
      allow(search_results).to receive_message_chain(:select, :count).and_return(5)
    end

    context "with standard pagination" do
      it "paginates with the 'per' value from params" do
        search
        expect(paginatable_array).to have_received(:page).with("2")
        # Correctly check that .per is called on the page_scope object
        expect(page_scope).to have_received(:per).with("20")
      end

      context "when 'per' is not in params" do
        let(:params) { { page: "2" } }

        it "uses the default_per_page value" do
          search
          # Correctly check that .per is called on the page_scope object
          expect(page_scope).to have_received(:per).with(15)
        end
      end
    end

    context "when 'all' param is present" do
      let(:params) { { all: "1" } }

      it "paginates with a 'per' value equal to the total count" do
        search
        expect(paginatable_array).to have_received(:page).with(1)
        # Correctly check that .per is called on the page_scope object
        expect(page_scope).to have_received(:per).with(5)
      end

      context "when the result set is empty" do
        before do
          allow(search_results).to receive(:to_a).and_return([])
          allow(search_results).to receive_message_chain(:select, :count).and_return(0)
        end

        it "uses a 'per' value of 1 to avoid errors" do
          search
          # Correctly check that .per is called on the page_scope object
          expect(page_scope).to have_received(:per).with(1)
        end
      end
    end
  end
end
