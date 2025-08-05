require "rails_helper"

RSpec.describe(Search::Filters::BaseFilter) do
  let(:scope) { Medium.all }
  let(:params) { { key: "value", another_key: "another_value" } }
  let(:user) { create(:user) }
  let(:filter) { described_class.new(scope, params, user: user) }

  describe "#initialize" do
    it "sets the scope" do
      expect(filter.scope).to eq(scope)
    end

    it "sets the user" do
      expect(filter.user).to eq(user)
    end

    it "converts params to a HashWithIndifferentAccess" do
      expect(filter.params).to be_a(ActiveSupport::HashWithIndifferentAccess)
    end

    it "allows accessing params with string keys" do
      expect(filter.params["key"]).to eq("value")
    end

    it "allows accessing params with symbol keys" do
      expect(filter.params[:key]).to eq("value")
      expect(filter.params[:another_key]).to eq("another_value")
    end

    context "when params is a non-hash object" do
      let(:params) { "string" }

      it "converts it to a hash" do
        expect(filter.params).to be_a(ActiveSupport::HashWithIndifferentAccess)
      end
    end

    context "when params is nil" do
      let(:params) { nil }

      it "defaults to an empty hash" do
        expect(filter.params).to be_a(ActiveSupport::HashWithIndifferentAccess)
        expect(filter.params).to be_empty
      end
    end
  end

  describe "#call" do
    it "raises NotImplementedError" do
      expect { filter.call }.to raise_error(
        NotImplementedError,
        "Subclasses must implement #call"
      )
    end
  end

  describe "#skip_filter?" do
    # Since BaseFilter is abstract, we use a dummy subclass for testing.
    let(:dummy_class) do
      Class.new(described_class) do
        # Dummy implementation
        def call
        end
      end
    end
    let(:filter) { dummy_class.new(scope, params, user: user) }

    subject(:skip) { filter.send(:skip_filter?, all_param: :all_items, ids_param: :item_ids) }

    context "when the 'all' parameter is '1'" do
      let(:params) { { all_items: "1", item_ids: [1] } }
      it { is_expected.to be(true) }
    end

    context "when the 'ids' parameter is nil" do
      let(:params) { { item_ids: nil } }
      it { is_expected.to be(true) }
    end

    context "when the 'ids' parameter is an empty array" do
      let(:params) { { item_ids: [] } }
      it { is_expected.to be(true) }
    end

    context "when the 'ids' parameter contains only blank values" do
      let(:params) { { item_ids: ["", nil] } }
      it { is_expected.to be(true) }
    end

    context "when valid IDs are provided and 'all' is not '1'" do
      let(:params) { { item_ids: [1, 2] } }
      it { is_expected.to be(false) }
    end

    context "when the 'all' parameter is not '1'" do
      let(:params) { { all_items: "0", item_ids: [1] } }
      it { is_expected.to be(false) }
    end
  end
end
