require "rails_helper"

RSpec.describe(Search::ControllerSearcher) do
  # --- Test Doubles & Setup ---
  let(:controller) { instance_spy(ApplicationController, "Controller") }
  let(:user) { create(:user) }
  let(:model_class) { class_spy(Course, "ModelClass") }
  let(:configurator_class) { class_spy(Search::Configurators::BaseSearchConfigurator, "ConfiguratorClass") }
  let(:instance_variable_name) { :courses }
  let(:default_per_page) { 15 }

  # Params from the controller
  let(:search_params) { { fulltext: "Ruby" } }
  let(:pagination_params) { { page: 2, per: 15 } }

  # Results from collaborators
  let(:configurator_result) do
    instance_double(
      Search::Configurators::BaseSearchConfigurator::Configuration,
      filters: [double("FilterClass")],
      params: { fulltext: "Ruby", processed: true } # Simulate processed params
    )
  end
  let(:paginated_search_result) do
    instance_double(
      Search::PaginatedSearcher::SearchResult,
      results: [double("Result1"), double("Result2")],
      total_count: 123
    )
  end

  subject(:search) do
    described_class.call(
      controller: controller,
      model_class: model_class,
      configurator_class: configurator_class,
      instance_variable_name: instance_variable_name,
      default_per_page: default_per_page
    )
  end

  before do
    # Stub controller methods
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:params).and_return(pagination_params)
    # Stub the private #search_params method on the controller
    allow(controller).to receive(:send).with(:search_params).and_return(search_params)
    # Allow the controller spy to receive instance_variable_set
    allow(controller).to receive(:instance_variable_set)

    # Stub collaborator class methods
    allow(configurator_class).to receive(:call).and_return(configurator_result)
    allow(Search::PaginatedSearcher).to receive(:call).and_return(paginated_search_result)
  end

  # --- Tests ---

  describe ".call" do
    it "initializes an instance and calls #call on it" do
      searcher_instance = instance_spy(described_class)
      allow(described_class).to receive(:new).and_return(searcher_instance)

      search

      expect(described_class).to have_received(:new).with(
        controller: controller,
        model_class: model_class,
        configurator_class: configurator_class,
        instance_variable_name: instance_variable_name,
        default_per_page: default_per_page
      )
      expect(searcher_instance).to have_received(:call)
    end
  end

  describe "orchestration logic" do
    it "calls the configurator to get search setup" do
      search
      expect(configurator_class).to have_received(:call).with(
        user: user,
        search_params: search_params
      )
    end

    it "calls the PaginatedSearcher with the correct configuration" do
      search
      # Use an argument matcher to check the contents of the config struct
      expected_paginated_config = have_attributes(
        class: Search::PaginatedSearcher::SearchConfig,
        search_params: configurator_result.params,
        pagination_params: pagination_params,
        default_per_page: default_per_page
      )

      expect(Search::PaginatedSearcher).to have_received(:call).with(
        model_class: model_class,
        filter_classes: configurator_result.filters,
        user: user,
        config: expected_paginated_config
      )
    end

    it "assigns the results and total count to the controller" do
      search
      # Check for @total
      expect(controller).to have_received(:instance_variable_set)
        .with(:@total, paginated_search_result.total_count)

      # Check for @<instance_variable_name>
      expect(controller).to have_received(:instance_variable_set)
        .with("@#{instance_variable_name}", paginated_search_result.results)
    end
  end
end
