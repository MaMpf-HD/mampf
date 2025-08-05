require "rails_helper"

RSpec.describe(Search::PaginatedSearcher) do
  let(:user) { create(:user) }
  let(:model_class) { class_spy(Course, "ModelClass") }
  let(:filter_classes) { [double("FilterClass")] }
  let(:search_params) { {} }
  let(:pagination_params) { { page: 2 } }
  let(:default_per_page) { 25 }
  let(:config) do
    described_class::SearchConfig.new(
      search_params: search_params,
      pagination_params: pagination_params,
      default_per_page: default_per_page
    )
  end

  subject(:search_result) do
    described_class.call(
      model_class: model_class,
      filter_classes: filter_classes,
      user: user,
      config: config
    )
  end

  # Mocks for dependencies
  let(:model_searcher_instance) { instance_spy(Search::ModelSearcher, call: search_scope) }
  let(:search_scope) { instance_spy(ActiveRecord::Relation, "SearchScope") }
  let(:paginated_array) { double("PaginatedArray") }

  before do
    # Stub ModelSearcher
    allow(Search::ModelSearcher).to receive(:new).and_return(model_searcher_instance)
    # Stub Kaminari
    allow(Kaminari).to receive(:paginate_array).and_return(paginated_array)
    allow(paginated_array).to receive(:page).and_return(paginated_array)
    allow(paginated_array).to receive(:per).and_return(paginated_array)
    # Stub the scope's to_a method
    allow(search_scope).to receive(:to_a).and_return([double("record1"), double("record2")])
  end

  describe "#call" do
    it "initializes and calls ModelSearcher" do
      search_result
      expect(Search::ModelSearcher).to have_received(:new).with(
        model_class,
        search_params,
        filter_classes,
        user: user
      )
      expect(model_searcher_instance).to have_received(:call)
    end

    context "for counting logic" do
      context "when the scope has no group_values" do
        before do
          allow(search_scope).to receive(:group_values).and_return([])
          allow(search_scope).to receive_message_chain(:select, :count).and_return(100)
        end

        it "calculates count using select(:id).count" do
          search_result
          expect(search_scope).to have_received(:select).with(:id)
        end

        it "returns the correct total_count" do
          expect(search_result.total_count).to eq(100)
        end
      end

      context "when the scope has group_values" do
        let(:subquery_scope) { double("SubqueryScope") }
        before do
          allow(search_scope).to receive(:group_values).and_return([:some_column])
          allow(model_class).to receive(:from).with(search_scope,
                                                    :subquery).and_return(subquery_scope)
          allow(subquery_scope).to receive(:count).and_return(50)
        end

        it "calculates count using a subquery" do
          search_result
          expect(model_class).to have_received(:from).with(search_scope, :subquery)
          expect(subquery_scope).to have_received(:count)
        end

        it "returns the correct total_count" do
          expect(search_result.total_count).to eq(50)
        end
      end
    end

    context "for pagination logic" do
      before do
        # Provide a generic count for these tests
        allow(search_scope).to receive(:group_values).and_return([])
        allow(search_scope).to receive_message_chain(:select, :count).and_return(100)
      end

      it "calls Kaminari.paginate_array with the scope as an array and the total count" do
        search_result
        expect(Kaminari).to have_received(:paginate_array).with(search_scope.to_a, total_count: 100)
      end

      it "applies the page number from pagination_params" do
        search_result
        expect(paginated_array).to have_received(:page).with(2)
      end

      context "when :per is in search_params" do
        let(:search_params) { { per: 5 } }
        it "uses the :per value from search_params" do
          search_result
          expect(paginated_array).to have_received(:per).with(5)
        end
      end

      context "when :per is not in search_params" do
        it "uses the default_per_page from the config" do
          search_result
          expect(paginated_array).to have_received(:per).with(25)
        end
      end

      context "when :per and default_per_page are not available" do
        let(:default_per_page) { nil }
        it "falls back to 10" do
          search_result
          expect(paginated_array).to have_received(:per).with(10)
        end
      end
    end

    it "returns a SearchResult struct with the final results" do
      expect(search_result).to be_a(described_class::SearchResult)
      expect(search_result.results).to eq(paginated_array)
    end
  end
end
