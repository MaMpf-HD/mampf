require "rails_helper"

RSpec.describe(Search::Filters::BaseFilter) do
  # Define a dummy class that inherits from BaseFilter for testing purposes.
  let(:dummy_class) do
    Class.new(described_class) do
      # A dummy implementation for testing.
      def call
        "call method was executed"
      end
    end
  end

  let(:scope) { Medium.all }
  let(:params) { { key: "value" } }
  let(:user) { create(:user) }

  describe "#initialize" do
    subject(:filter) { described_class.new(scope: scope, params: params, user: user) }

    it "sets the scope" do
      expect(filter.scope).to eq(scope)
    end

    it "sets the user" do
      expect(filter.user).to eq(user)
    end

    it "converts params to a HashWithIndifferentAccess" do
      expect(filter.params).to be_a(ActiveSupport::HashWithIndifferentAccess)
      expect(filter.params[:key]).to eq("value")
    end

    context "when params is nil" do
      let(:params) { nil }

      it "defaults to an empty hash" do
        expect(filter.params).to be_empty
      end
    end
  end

  describe ".apply" do
    it "initializes a new instance and calls #call" do
      filter_instance = instance_spy(dummy_class)
      allow(dummy_class).to receive(:new).and_return(filter_instance)

      dummy_class.apply(scope: scope, params: params, user: user)

      expect(dummy_class).to have_received(:new)
        .with(scope: scope, params: params, user: user)
      expect(filter_instance).to have_received(:call)
    end
  end

  describe "#call" do
    subject(:filter) { described_class.new(scope: scope, params: params, user: user) }

    it "raises NotImplementedError" do
      expect { filter.call }.to raise_error(
        NotImplementedError,
        "Subclasses must implement #call"
      )
    end
  end

  describe "#skip_filter?" do
    # Use the dummy class for testing the private method
    subject(:filter) { dummy_class.new(scope: scope, params: params, user: user) }

    let(:skip) { filter.send(:skip_filter?, all_param: :all_items, ids_param: :item_ids) }

    context "when the 'all' parameter is '1'" do
      let(:params) { { all_items: "1", item_ids: [1] } }
      it "returns true" do
        expect(skip).to be(true)
      end
    end

    context "when the 'ids' parameter is nil" do
      let(:params) { { item_ids: nil } }
      it "returns true" do
        expect(skip).to be(true)
      end
    end

    context "when the 'ids' parameter is an empty array" do
      let(:params) { { item_ids: [] } }
      it "returns true" do
        expect(skip).to be(true)
      end
    end

    context "when the 'ids' parameter contains only blank values" do
      let(:params) { { item_ids: ["", nil] } }
      it "returns true" do
        expect(skip).to be(true)
      end
    end

    context "when valid IDs are provided and 'all' is not '1'" do
      let(:params) { { item_ids: [1, 2] } }
      it "returns false" do
        expect(skip).to be(false)
      end
    end
  end
end
