require "rails_helper"

RSpec.describe(Search::Searchers::ModelSearcher) do
  # --- Test Doubles & Setup ---
  let(:user) { create(:user) }
  let(:model_class) { class_spy(Course, "ModelClass") }
  let(:params) { { key: "value" } }
  let(:filter_classes) { [double("FilterClass1")] }
  let(:custom_orderer_class) { class_spy(Search::Orderers::BaseOrderer, "CustomOrderer") }

  # Set up a double for the configuration object
  let(:config) do
    instance_double(
      Search::Configurators::Configuration,
      filters: filter_classes,
      params: params,
      orderer_class: orderer_class_from_config
    )
  end

  # Stubs for the chained scopes
  let(:initial_scope) { double("InitialScope") }
  let(:filtered_scope) { instance_spy(ActiveRecord::Relation, "FilteredScope") }
  let(:distinct_scope) { instance_spy(ActiveRecord::Relation, "DistinctScope") }
  let(:ordered_scope) { double("OrderedScope") }

  # The subject now calls the .search class method directly.
  subject(:search) do
    described_class.search(
      model_class: model_class,
      user: user,
      config: config
    )
  end

  before do
    # Stub the common chain of calls
    allow(model_class).to receive(:all).and_return(initial_scope)
    allow(Search::Filters::FilterApplier).to receive(:apply).and_return(filtered_scope)
    allow(filtered_scope).to receive(:distinct).and_return(distinct_scope)
  end

  # The describe block now targets the .search method.
  describe ".search" do
    # This shared example now relies on a `let(:expected_orderer)` to be defined
    # in the context where it is included.
    shared_examples "search orchestration" do
      it "orchestrates the search by calling services in the correct order" do
        # Trigger the call by evaluating the subject.
        search

        # 1. Starts with the model's .all scope
        expect(model_class).to have_received(:all)

        # 2. Applies the filters via the FilterApplier
        expect(Search::Filters::FilterApplier).to have_received(:apply).with(
          scope: initial_scope,
          user: user,
          config: config
        )

        # 3. Makes the results distinct
        expect(filtered_scope).to have_received(:distinct)

        # 4. Applies the final ordering using the expected orderer
        expect(expected_orderer).to have_received(:call).with(
          model_class: model_class,
          scope: distinct_scope,
          search_params: params
        )
      end

      it "returns the final, ordered scope" do
        expect(search).to eq(ordered_scope)
      end
    end

    context "with the default orderer" do
      let(:orderer_class_from_config) { nil }
      let(:expected_orderer) { Search::Orderers::SearchOrderer }

      before do
        allow(expected_orderer).to receive(:call).and_return(ordered_scope)
      end

      include_examples "search orchestration"
    end

    context "with a custom orderer class" do
      let(:orderer_class_from_config) { custom_orderer_class }
      let(:expected_orderer) { custom_orderer_class }

      before do
        allow(expected_orderer).to receive(:call).and_return(ordered_scope)
      end

      include_examples "search orchestration"
    end
  end
end
