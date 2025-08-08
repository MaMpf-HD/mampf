require "rails_helper"

RSpec.describe(Search::Filters::FilterApplier) do
  let(:user) { create(:user) }
  let(:params) { { key: "value" } }
  let(:initial_scope) { double("InitialScope") }

  # Create test doubles for the scopes returned by each filter
  let(:scope_after_filter1) { double("ScopeAfterFilter1") }
  let(:scope_after_filter2) { double("ScopeAfterFilter2") }

  # Create test doubles for filter classes, stubbing the .apply method
  let(:filter_class1) { class_double(Search::Filters::BaseFilter, apply: scope_after_filter1) }
  let(:filter_class2) { class_double(Search::Filters::BaseFilter, apply: scope_after_filter2) }

  # Create a double for the configuration object
  let(:config) do
    instance_double(
      Search::Configurators::BaseSearchConfigurator::Configuration,
      filters: filter_classes,
      params: params
    )
  end

  subject(:apply_filters) do
    described_class.call(
      scope: initial_scope,
      user: user,
      config: config
    )
  end

  describe ".call" do
    context "when given a configuration with an empty list of filters" do
      let(:filter_classes) { [] }

      it "returns the original scope" do
        expect(apply_filters).to eq(initial_scope)
      end
    end

    context "when given a configuration with a list of filters" do
      let(:filter_classes) { [filter_class1, filter_class2] }

      it "calls .apply on each filter in sequence" do
        # Trigger the call
        apply_filters

        # Expect the first filter to be applied to the initial scope
        expect(filter_class1).to have_received(:apply)
          .with(scope: initial_scope, params: params, user: user)

        # Expect the second filter to be applied to the result of the first
        expect(filter_class2).to have_received(:apply)
          .with(scope: scope_after_filter1, params: params, user: user)
      end

      it "returns the result from the final filter" do
        expect(apply_filters).to eq(scope_after_filter2)
      end
    end
  end
end
