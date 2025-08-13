require "rails_helper"

RSpec.describe(Search::Searchers::ControllerSearcher) do
  # --- Test Doubles & Setup ---
  let(:controller) { instance_spy(ApplicationController, "Controller") }
  let(:user) { create(:user) }
  let(:model_class) { class_spy(Course, "ModelClass") }
  let(:configurator_class) { class_spy(Search::Configurators::BaseSearchConfigurator, "ConfiguratorClass") }
  let(:instance_variable_name) { :courses }
  let(:options) { { default_per_page: 15 } }
  let(:cookies) { { "some_cookie" => "some_value" } }

  # The hash returned by the controller's #search_params method
  let(:permitted_search_params) { { fulltext: "Ruby", per: 15 } }
  # The top-level params hash, containing :page
  let(:top_level_params) { ActionController::Parameters.new(page: 2) }
  # The final merged params we expect to be passed to the configurator
  let(:expected_merged_params) { { fulltext: "Ruby", per: 15, page: 2 } }

  # The Configuration object returned by the configurator
  let(:configurator_result) do
    instance_double(Search::Configurators::Configuration)
  end
  # The SearchResult object returned by the paginated searcher
  let(:paginated_search_result) do
    instance_double(
      Search::Searchers::PaginatedSearcher::SearchResult,
      results: [double("Result1")],
      total_count: 42
    )
  end

  subject(:search) do
    described_class.call(
      controller: controller,
      model_class: model_class,
      configurator_class: configurator_class,
      instance_variable_name: instance_variable_name,
      options: options
    )
  end

  before do
    # Stub controller methods
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:params).and_return(top_level_params)
    # Allow .send to be called for both :search_params and :cookies
    allow(controller).to receive(:send).with(:search_params).and_return(permitted_search_params)
    allow(controller).to receive(:send).with(:cookies).and_return(cookies)
    allow(controller).to receive(:instance_variable_set)

    # Stub collaborator class methods
    allow(configurator_class).to receive(:call).and_return(configurator_result)
    allow(Search::Searchers::PaginatedSearcher).to receive(:call)
      .and_return(paginated_search_result)
  end

  # --- Tests ---

  describe "orchestration logic" do
    it "calls the configurator with correctly merged params and cookies" do
      search
      expect(configurator_class).to have_received(:call).with(
        user: user,
        search_params: expected_merged_params,
        cookies: cookies
      )
    end

    it "calls the PaginatedSearcher with the config from the configurator" do
      search
      expect(Search::Searchers::PaginatedSearcher).to have_received(:call).with(
        model_class: model_class,
        user: user,
        config: configurator_result,
        default_per_page: 15
      )
    end

    it "assigns the results and total count to the controller" do
      search
      expect(controller).to have_received(:instance_variable_set)
        .with(:@total, paginated_search_result.total_count)
      expect(controller).to have_received(:instance_variable_set)
        .with("@#{instance_variable_name}", paginated_search_result.results)
    end

    context "when the configurator returns nil" do
      let(:empty_scope) { double("EmptyScope") }
      before do
        allow(configurator_class).to receive(:call).and_return(nil)
        allow(model_class).to receive(:none).and_return(empty_scope)
      end

      it "does not call the PaginatedSearcher" do
        search
        expect(Search::Searchers::PaginatedSearcher).not_to have_received(:call)
      end

      it "assigns empty results to the controller" do
        search
        expect(controller).to have_received(:instance_variable_set).with(:@total, 0)
        expect(controller).to have_received(:instance_variable_set).with(
          "@#{instance_variable_name}", empty_scope
        )
      end
    end

    context "with a custom params_method_name" do
      let(:options) { { params_method_name: :custom_search_params } }
      before do
        allow(controller).to receive(:send).with(:custom_search_params)
                                           .and_return(permitted_search_params)
      end

      it "calls the custom method to get params" do
        search
        expect(controller).to have_received(:send).with(:custom_search_params)
      end
    end
  end
end
