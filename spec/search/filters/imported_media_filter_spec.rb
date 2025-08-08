require "rails_helper"

RSpec.describe(Search::Filters::ImportedMediaFilter) do
  let(:user) { create(:user) }
  let(:project_name) { "LessonMaterial" }
  let!(:lecture) { create(:lecture) }
  let!(:medium_in_initial_scope) { create(:valid_medium, sort: project_name) }
  let(:initial_scope) { Medium.where(id: medium_in_initial_scope.id) }
  let(:params) { { id: lecture.id, project: project_name } }

  subject(:filtered_scope) do
    described_class.new(scope: initial_scope, params: params, user: user).call
  end

  context "with invalid or missing parameters" do
    context "when lecture_id is missing" do
      let(:params) { { project: project_name } }
      it "returns the original scope" do
        expect(filtered_scope).to contain_exactly(medium_in_initial_scope)
      end
    end

    context "when project is missing" do
      let(:params) { { lecture_id: lecture.id } }
      it "returns the original scope" do
        expect(filtered_scope).to contain_exactly(medium_in_initial_scope)
      end
    end

    context "when lecture is not found" do
      let(:params) { { lecture_id: -1, project: project_name } }
      it "returns the original scope" do
        expect(filtered_scope).to contain_exactly(medium_in_initial_scope)
      end
    end
  end

  context "with valid parameters" do
    # Ensure the source lecture of imported media is published, otherwise
    # Medium#reset_released_status will nullify `released`.
    let!(:source_lecture) { create(:lecture, :released_for_all) }

    # Media that should be added
    let!(:imported_medium) do
      create(:lecture_medium, sort: project_name, teachable: source_lecture, released: "all")
    end

    # Media that should NOT be added
    let!(:wrong_project_medium) do
      create(:lecture_medium, sort: "WorkedExample", teachable: source_lecture, released: "all")
    end
    let!(:not_visible_medium) do
      create(:lecture_medium, sort: project_name, teachable: source_lecture,
                              released: "subscribers")
    end
    let!(:other_lecture_medium) do
      create(:lecture_medium, sort: project_name, released: "all")
    end

    before do
      # Create Import records directly to associate media with the lecture.
      # This is more reliable than assigning to the has_many :through association.
      create(:import, teachable: lecture, medium: imported_medium)
      create(:import, teachable: lecture, medium: wrong_project_medium)
      create(:import, teachable: lecture, medium: not_visible_medium)
    end

    it "returns a scope containing media from the initial scope AND the lecture's imported media" do
      expect(filtered_scope).to contain_exactly(
        medium_in_initial_scope,
        imported_medium,
        not_visible_medium
      )
    end

    it "does not include imported media from other projects" do
      expect(filtered_scope).not_to include(wrong_project_medium)
    end

    it "does not include media from other lectures" do
      expect(filtered_scope).not_to include(other_lecture_medium)
    end

    context "when a medium is in both the initial scope and imported media" do
      let!(:initial_scope) { Medium.where(id: imported_medium.id) }

      it "includes the medium only once" do
        expect(filtered_scope).to contain_exactly(
          imported_medium,
          not_visible_medium
        )
      end
    end
  end
end
