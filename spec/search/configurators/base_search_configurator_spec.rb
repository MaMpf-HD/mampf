require "rails_helper"

RSpec.describe(Search::Configurators::BaseSearchConfigurator) do
  let(:user) { create(:user) }
  let(:search_params) { { key: "value", another_key: "another_value" } }
  let(:configurator) { described_class.new(user: user, search_params: search_params) }

  describe "#initialize" do
    it "sets the user" do
      expect(configurator.user).to eq(user)
    end

    it "converts search_params to a HashWithIndifferentAccess" do
      expect(configurator.search_params).to be_a(ActiveSupport::HashWithIndifferentAccess)
    end

    it "allows accessing params with string keys" do
      expect(configurator.search_params["key"]).to eq("value")
    end

    it "allows accessing params with symbol keys" do
      expect(configurator.search_params[:key]).to eq("value")
      expect(configurator.search_params[:another_key]).to eq("another_value")
    end

    context "when search_params is nil" do
      let(:search_params) { nil }

      it "defaults to an empty hash" do
        expect(configurator.search_params).to be_a(ActiveSupport::HashWithIndifferentAccess)
        expect(configurator.search_params).to be_empty
      end
    end
  end

  describe "#call" do
    it "raises NotImplementedError" do
      expect { configurator.call }.to raise_error(NotImplementedError)
    end
  end

  describe ".configure" do
    # Use a dummy subclass to test the behavior of the abstract base class's .configure method
    let(:dummy_configurator_class) do
      Class.new(described_class) do
        def call
          # A dummy implementation that returns a known value
          "call method was executed"
        end
      end
    end

    it "initializes an instance of the subclass and calls its #call method" do
      # Create a spy for the instance to verify that #call is invoked
      dummy_instance = instance_spy(dummy_configurator_class)
      allow(dummy_configurator_class).to receive(:new).and_return(dummy_instance)

      # Trigger the class method
      dummy_configurator_class.configure(user: user, search_params: search_params)

      # Verify that .new was called with the correct arguments
      expect(dummy_configurator_class).to have_received(:new)
        .with(user: user, search_params: search_params, cookies: {})

      # Verify that the instance's #call method was executed
      expect(dummy_instance).to have_received(:call)
    end
  end

  describe "Configuration" do
    it "can be initialized with filters and params" do
      filters = [Search::Filters::FulltextFilter]
      params = { fulltext: "test" }
      configuration = Search::Configurators::Configuration.new(filters: filters, params: params)

      expect(configuration.filters).to eq(filters)
      expect(configuration.params).to eq(params)
    end
  end
end
