require "rails_helper"

RSpec.describe(Search::Filters::FilterApplier) do
  let(:user) { create(:user) }
  let(:params) { { key: "value" } }
  let(:initial_scope) { double("InitialScope") }

  # Create test doubles for filter classes
  let(:filter_class1) { class_double(Search::Filters::BaseFilter, new: filter_instance1) }
  let(:filter_class2) { class_double(Search::Filters::BaseFilter, new: filter_instance2) }

  # Create test doubles for filter instances
  let(:filter_instance1) { instance_double(Search::Filters::BaseFilter, call: scope_after_filter1) }
  let(:filter_instance2) { instance_double(Search::Filters::BaseFilter, call: scope_after_filter2) }

  # Create test doubles for the scopes returned by each filter
  let(:scope_after_filter1) { double("ScopeAfterFilter1") }
  let(:scope_after_filter2) { double("ScopeAfterFilter2") }

  subject(:apply_filters) do
    described_class.call(
      scope: initial_scope,
      filter_classes: filter_classes,
      params: params,
      user: user
    )
  end

  describe "#call" do
    context "when given an empty list of filters" do
      let(:filter_classes) { [] }

      it "returns the original scope" do
        expect(apply_filters).to eq(initial_scope)
      end
    end

    context "when given a list of filters" do
      let(:filter_classes) { [filter_class1, filter_class2] }

      it "initializes and calls each filter in sequence" do
        # Trigger the call
        apply_filters

        # Expect the first filter to be initialized with the initial scope
        expect(filter_class1).to have_received(:new)
          .with(initial_scope, params.with_indifferent_access, user: user)
        expect(filter_instance1).to have_received(:call)

        # Expect the second filter to be initialized with the result of the first
        expect(filter_class2).to have_received(:new)
          .with(scope_after_filter1, params.with_indifferent_access, user: user)
        expect(filter_instance2).to have_received(:call)
      end

      it "returns the result from the final filter" do
        expect(apply_filters).to eq(scope_after_filter2)
      end
    end
  end
end
