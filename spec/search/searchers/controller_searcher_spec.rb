require "rails_helper"

RSpec.describe(Search::Searchers::ControllerSearcher) do
  let(:controller) { instance_spy(ApplicationController, "Controller") }
  let(:user) { create(:user) }
  let(:model_class) { class_spy(Course, "ModelClass") }
  let(:configurator_class) { class_spy(Search::Configurators::BaseSearchConfigurator, "ConfiguratorClass") }
  let(:options) { { default_per_page: 15 } }
  let(:cookies) { { "some_cookie" => "some_value" } }

  let(:permitted_search_params) { { fulltext: "Ruby", per: 15 } }
  let(:top_level_params) { ActionController::Parameters.new(page: 2) }
  let(:expected_merged_params) { { fulltext: "Ruby", per: 15, page: 2 } }

  let(:configurator_result) do
    instance_double(Search::Configurators::Configuration)
  end

  let(:pagy_object) { instance_double(Pagy) }
  let(:paginated_search_result) do
    instance_double(
      Search::Searchers::SearchResult,
      results: [double("Result1")],
      pagy: pagy_object
    )
  end

  # The subject now calls the .search method and no longer needs instance_variable_name
  subject(:search) do
    described_class.search(
      controller: controller,
      model_class: model_class,
      configurator_class: configurator_class,
      options: options
    )
  end

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:params).and_return(top_level_params)
    allow(controller).to receive(:send).with(:search_params).and_return(permitted_search_params)
    allow(controller).to receive(:send).with(:cookies).and_return(cookies)

    # Stub collaborator class methods
    allow(configurator_class).to receive(:configure).and_return(configurator_result)
    allow(Search::Searchers::PaginatedSearcher).to receive(:search)
      .and_return(paginated_search_result)
  end

  # --- Tests ---

  describe ".search" do
    it "calls the configurator with correctly merged params and cookies" do
      search
      expect(configurator_class).to have_received(:configure).with(
        user: user,
        search_params: expected_merged_params,
        cookies: cookies
      )
    end

    it "calls the PaginatedSearcher with the config from the configurator" do
      search
      expect(Search::Searchers::PaginatedSearcher).to have_received(:search).with(
        model_class: model_class,
        user: user,
        config: configurator_result,
        default_per_page: 15
      )
    end

    it "returns the result from the PaginatedSearcher" do
      expect(search).to eq(paginated_search_result)
    end

    context "when the configurator returns nil" do
      let(:empty_scope) { double("EmptyScope") }
      let(:empty_pagy) { instance_double(Pagy) }
      before do
        allow(configurator_class).to receive(:configure).and_return(nil)
        allow(model_class).to receive(:none).and_return(empty_scope)
        allow(Pagy).to receive(:new).and_return(empty_pagy)
      end

      it "does not call the PaginatedSearcher" do
        search
        expect(Search::Searchers::PaginatedSearcher).not_to have_received(:search)
      end

      it "returns an empty search result object" do
        result = search
        expect(result).to be_a(Search::Searchers::SearchResult)
        expect(result.results).to eq(empty_scope)
        expect(result.pagy).to eq(empty_pagy)
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
