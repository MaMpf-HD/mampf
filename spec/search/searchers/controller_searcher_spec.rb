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

  let(:config) do
    instance_double(Search::Configurators::Configuration,
                    params: { page: 2, per: 15 })
  end

  let(:search_results) { instance_spy(ActiveRecord::Relation, "SearchResults") }
  let(:pagy_object) { instance_double(Pagy) }
  let(:paginated_results) { [double("Result1")] }

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
    allow(controller).to receive(:pagy).and_return([pagy_object, paginated_results])

    allow(configurator_class).to receive(:configure).and_return(config)
    allow(Search::Searchers::ModelSearcher).to receive(:search).and_return(search_results)
  end

  describe ".search" do
    it "calls the configurator with correctly merged params and cookies" do
      search
      expect(configurator_class).to have_received(:configure).with(
        user: user,
        search_params: expected_merged_params,
        cookies: cookies
      )
    end

    it "calls ModelSearcher with the config from the configurator" do
      search
      expect(Search::Searchers::ModelSearcher).to have_received(:search).with(
        model_class: model_class,
        user: user,
        config: config
      )
    end

    it "calls pagy with the search results and correct options" do
      search
      expect(controller).to have_received(:pagy).with(
        :countish,
        search_results,
        limit: 15,
        page: 2
      )
    end

    it "returns a tuple of pagy and results" do
      pagy, results = search
      expect(pagy).to eq(pagy_object)
      expect(results).to eq(paginated_results)
    end

    context "when the configurator returns nil" do
      let(:empty_scope) { double("EmptyScope") }
      let(:empty_pagy) { instance_double(Pagy) }
      before do
        allow(configurator_class).to receive(:configure).and_return(nil)
        allow(model_class).to receive(:none).and_return(empty_scope)
        allow(Pagy).to receive(:new).and_return(empty_pagy)
      end

      it "does not call ModelSearcher" do
        search
        expect(Search::Searchers::ModelSearcher).not_to have_received(:search)
      end

      it "returns a tuple with empty pagy and empty scope" do
        pagy, results = search
        expect(pagy).to eq(empty_pagy)
        expect(results).to eq(empty_scope)
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

    context "when all param is present" do
      let(:config) do
        instance_double(Search::Configurators::Configuration,
                        params: { all: "1" })
      end
      let(:subquery_scope) { double("SubqueryScope") }
      let(:total_count) { 42 }

      before do
        allow(model_class).to receive(:from).with(search_results,
                                                  :subquery_for_count).and_return(subquery_scope)
        allow(subquery_scope).to receive(:count).and_return(total_count)
      end

      it "calculates the correct count and uses it as limit" do
        search
        expect(controller).to have_received(:pagy).with(
          :countish,
          search_results,
          limit: total_count,
          page: nil
        )
      end

      context "when count is zero" do
        let(:total_count) { 0 }

        it "uses 1 as minimum limit to avoid Pagy errors" do
          search
          expect(controller).to have_received(:pagy).with(
            :countish,
            search_results,
            limit: 1,
            page: nil
          )
        end
      end
    end
  end
end
