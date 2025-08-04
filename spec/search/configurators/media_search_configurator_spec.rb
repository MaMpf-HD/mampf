require "rails_helper"

RSpec.describe(Configurators::MediaSearchConfigurator) do
  let(:user) { create(:user) }
  let(:search_params) { {} }
  subject(:configuration) { described_class.call(user: user, search_params: search_params) }

  # Define the static list of base filters for media search
  let(:base_filters) do
    [
      Filters::ProperFilter,
      Filters::TypeFilter,
      Filters::TeachableFilter,
      Filters::TagFilter,
      Filters::EditorFilter,
      Filters::AnswerCountFilter,
      Filters::LectureScopeFilter,
      Filters::FulltextFilter
    ]
  end

  describe "#call" do
    describe "filter selection logic" do
      context "when the user is an active teachable editor" do
        before { allow(user).to receive(:active_teachable_editor?).and_return(true) }

        it "returns the base filters plus the MediumAccessFilter" do
          expected_filters = base_filters + [Filters::MediumAccessFilter]
          expect(configuration.filters).to match_array(expected_filters)
        end
      end

      context "when the user is not an active teachable editor" do
        before { allow(user).to receive(:active_teachable_editor?).and_return(false) }

        it "returns the base filters plus the MediumVisibilityFilter" do
          expected_filters = base_filters + [Filters::MediumVisibilityFilter]
          expect(configuration.filters).to match_array(expected_filters)
        end
      end
    end

    describe "parameter processing logic" do
      context "when the user is not an editor" do
        let(:search_params) { { access: "private", other: "value" } }
        before { allow(user).to receive(:active_teachable_editor?).and_return(false) }

        it "removes the :access parameter" do
          expect(configuration.params).not_to have_key(:access)
          expect(configuration.params).to have_key(:other)
        end
      end

      context "when the user is an editor" do
        let(:search_params) { { access: "private", other: "value" } }
        before { allow(user).to receive(:active_teachable_editor?).and_return(true) }

        it "preserves the :access parameter" do
          expect(configuration.params[:access]).to eq("private")
          expect(configuration.params).to have_key(:other)
        end
      end

      context "when searching from the start page with 'all_types' selected" do
        let(:search_params) { { all_types: "1", from: "start" } }
        let(:generic_sorts) { ["Question", "Remark"] }
        before { allow(Medium).to receive(:generic_sorts).and_return(generic_sorts) }

        it "sets the :types parameter to the list of generic media sorts" do
          expect(configuration.params[:types]).to eq(generic_sorts)
        end
      end

      context "when 'all_types' is selected but not from the start page" do
        let(:search_params) { { all_types: "1", from: "elsewhere" } }

        it "does not modify the params" do
          expect(configuration.params).to eq(search_params.with_indifferent_access)
        end
      end

      context "when not searching with 'all_types'" do
        let(:search_params) { { all_types: "0", from: "start" } }

        it "does not modify the params" do
          expect(configuration.params).to eq(search_params.with_indifferent_access)
        end
      end
    end
  end
end
