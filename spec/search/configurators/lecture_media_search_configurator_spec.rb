require "rails_helper"

RSpec.describe(Search::Configurators::LectureMediaSearchConfigurator) do
  describe ".call" do
    let(:user) { create(:user) }
    let(:lecture) { create(:lecture) }
    let(:search_params) { { id: lecture.id } }

    subject(:configuration) do
      described_class.call(user: user, search_params: search_params)
    end

    it "returns a configuration with the correct set of filters" do
      expected_filters = [
        Search::Filters::LectureMediaScopeFilter,
        Search::Filters::ImportedMediaFilter,
        Search::Filters::LectureMediaVisibilityFilter,
        Search::Filters::MediumVisibilityFilter
      ]
      expect(configuration.filters).to match_array(expected_filters)
    end

    it "returns a configuration with the correct orderer class" do
      expect(configuration.orderer_class).to eq(Search::Orderers::LectureMediaOrderer)
    end

    context "with parameter processing" do
      let(:cookies) { {} }

      subject(:configuration) do
        described_class.call(user: user, search_params: search_params, cookies: cookies)
      end

      context "when 'reverse' param is a string 'true'" do
        let(:search_params) { { id: lecture.id, reverse: "true" } }

        it "normalizes 'reverse' to a boolean true" do
          expect(configuration.params[:reverse]).to be(true)
        end
      end

      context "when a valid 'per' parameter is provided" do
        let(:search_params) { { id: lecture.id, per: "12" } }

        it "uses the provided 'per' value and sets the cookie" do
          expect(configuration.params[:per]).to eq(12)
          expect(cookies[:per]).to eq(12)
        end
      end

      context "when 'per' parameter is invalid but a valid cookie exists" do
        let(:search_params) { { id: lecture.id, per: "99" } }
        let(:cookies) { { per: "24" } }

        it "uses the 'per' value from the cookie" do
          expect(configuration.params[:per]).to eq(24)
        end
      end

      context "when 'per' parameter and cookie are both invalid" do
        let(:search_params) { { id: lecture.id, per: "99" } }
        let(:cookies) { { per: "100" } }

        it "falls back to the default 'per' value of 8" do
          expect(configuration.params[:per]).to eq(8)
        end
      end

      context "when 'all' is true in cookies" do
        let(:cookies) { { all: "true" } }

        it "sets 'all' to true in the processed params" do
          expect(configuration.params[:all]).to be(true)
        end
      end

      context "when 'all' is true, clearing a pre-existing 'per' cookie" do
        let(:search_params) { { id: lecture.id, all: "true" } }
        let(:cookies) { { per: "24" } } # Pre-populate the cookie

        it "deletes the 'per' cookie" do
          # The configuration subject is triggered by being called here.
          expect { configuration }.to change { cookies.key?(:per) }.from(true).to(false)
        end
      end

      context "when 'per' is provided, overriding a stale 'all' cookie" do
        let(:search_params) { { id: lecture.id, per: "4" } }
        let(:cookies) { { all: "true" } }

        it "sets 'all' to false and uses the new 'per' value" do
          expect(configuration.params[:all]).to be(false)
          expect(configuration.params[:per]).to eq(4)
          expect(cookies[:all]).to eq("false")
        end
      end
    end
  end
end
