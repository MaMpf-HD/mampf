require "rails_helper"

RSpec.describe(ModelSearcher) do
  let(:user) { create(:user) }
  let(:params) { { key: "value" } }
  let(:model_class) { class_spy(Course, "ModelClass") }
  let(:filter_classes) { [double("FilterClass1"), double("FilterClass2")] }

  subject(:searcher) do
    described_class.new(model_class, params, filter_classes, user: user)
  end

  describe "#initialize" do
    it "assigns the model_class" do
      expect(searcher.model_class).to eq(model_class)
    end

    it "assigns the filter_classes" do
      expect(searcher.filter_classes).to eq(filter_classes)
    end

    it "assigns the user" do
      expect(searcher.user).to eq(user)
    end

    it "converts params to a HashWithIndifferentAccess" do
      expect(searcher.params).to be_a(ActiveSupport::HashWithIndifferentAccess)
      expect(searcher.params[:key]).to eq("value")
    end
  end

  describe "#call" do
    let(:initial_scope) { double("InitialScope") }
    let(:filtered_scope) { instance_spy(ActiveRecord::Relation, "FilteredScope") }
    let(:distinct_scope) { instance_spy(ActiveRecord::Relation, "DistinctScope") }
    let(:ordered_scope) { double("OrderedScope") }

    before do
      # Stub the chain of calls
      allow(model_class).to receive(:all).and_return(initial_scope)
      allow(FilterApplier).to receive(:call).and_return(filtered_scope)
      allow(filtered_scope).to receive(:distinct).and_return(distinct_scope)
      allow(SearchOrderer).to receive(:call).and_return(ordered_scope)
    end

    it "orchestrates the search by calling services in the correct order" do
      # Trigger the call
      searcher.call

      # 1. Starts with the model's .all scope
      expect(model_class).to have_received(:all)

      # 2. Applies the filters
      expect(FilterApplier).to have_received(:call).with(
        scope: initial_scope,
        filter_classes: filter_classes,
        params: params.with_indifferent_access,
        user: user
      )

      # 3. Makes the results distinct
      expect(filtered_scope).to have_received(:distinct)

      # 4. Applies the final ordering
      expect(SearchOrderer).to have_received(:call).with(
        scope: distinct_scope,
        model_class: model_class,
        params: params.with_indifferent_access
      )
    end

    it "returns the final, ordered scope" do
      expect(searcher.call).to eq(ordered_scope)
    end
  end
end
