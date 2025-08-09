require "rails_helper"

RSpec.describe(Search::Configurators::MediaSearchConfigurator) do
  let(:user) { create(:user) }
  let(:search_params) { {} }
  let(:generic_sorts) { ["Question", "Remark"] } # Mock generic sorts for predictability
  subject(:configuration) { described_class.call(user: user, search_params: search_params) }

  before do
    allow(Medium).to receive(:generic_sorts).and_return(generic_sorts)
  end

  describe "#call" do
    # This part of the spec is still valid and does not need changes.
    describe "filter selection logic" do
      let(:base_filters) do
        [
          Search::Filters::ProperFilter, Search::Filters::TypeFilter,
          Search::Filters::TeachableFilter, Search::Filters::TagFilter,
          Search::Filters::EditorFilter, Search::Filters::AnswerCountFilter,
          Search::Filters::LectureScopeFilter, Search::Filters::FulltextFilter
        ]
      end

      context "when the user is an active teachable editor" do
        before { allow(user).to receive(:active_teachable_editor?).and_return(true) }

        it "returns the base filters plus the MediumAccessFilter" do
          expected_filters = base_filters + [Search::Filters::MediumAccessFilter]
          expect(configuration.filters).to match_array(expected_filters)
        end
      end

      context "when the user is not an active teachable editor" do
        before { allow(user).to receive(:active_teachable_editor?).and_return(false) }

        it "returns the base filters plus the MediumVisibilityFilter" do
          expected_filters = base_filters + [Search::Filters::MediumVisibilityFilter]
          expect(configuration.filters).to match_array(expected_filters)
        end
      end
    end

    describe "parameter processing logic" do
      context "for a generic user (non-editor)" do
        before { allow(user).to receive(:active_teachable_editor?).and_return(false) }

        it "removes the :access parameter" do
          search_params[:access] = "private"
          expect(configuration.params).not_to have_key(:access)
        end

        context "when specific types are requested" do
          let(:search_params) { { types: ["Question", "RestrictedType"] } }

          it "filters the types to only include generic sorts" do
            expect(configuration.params[:types]).to eq(["Question"])
          end
        end

        context "when 'all_types' is checked" do
          let(:search_params) { { all_types: "1" } }

          it "sets types to all generic sorts" do
            expect(configuration.params[:types]).to eq(generic_sorts)
          end

          it "SECURITY: forces 'all_types' to '0' to ensure TypeFilter is applied" do
            expect(configuration.params[:all_types]).to eq("0")
          end
        end
      end

      context "for an editor" do
        before { allow(user).to receive(:active_teachable_editor?).and_return(true) }

        context "when searching from the start page (from: 'start')" do
          it "restricts types to generic sorts if 'all_types' is checked" do
            search_params.merge!(all_types: "1", from: "start")
            expect(configuration.params[:types]).to eq(generic_sorts)
          end

          it "filters provided types to only include generic sorts" do
            search_params.merge!(types: ["Question", "RestrictedType"], from: "start")
            expect(configuration.params[:types]).to eq(["Question"])
          end

          it "forces 'all_types' to '0' for UI consistency" do
            search_params.merge!(all_types: "1", from: "start")
            expect(configuration.params[:all_types]).to eq("0")
          end
        end

        context "when not searching from the start page (admin search)" do
          it "preserves the :access parameter" do
            search_params[:access] = "private"
            expect(configuration.params[:access]).to eq("private")
          end

          it "does not restrict the types" do
            search_params[:types] = ["Question", "RestrictedType"]
            expect(configuration.params[:types]).to eq(["Question", "RestrictedType"])
          end

          it "does not modify the 'all_types' flag" do
            search_params[:all_types] = "1"
            expect(configuration.params[:all_types]).to eq("1")
          end
        end
      end
    end
  end
end
