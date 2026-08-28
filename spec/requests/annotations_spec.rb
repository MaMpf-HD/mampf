require "rails_helper"

RSpec.describe("Annotations", type: :request) do
  let(:medium) { create(:valid_medium) }
  let(:owner) { create(:confirmed_user) }
  let(:other_user) { create(:confirmed_user) }
  let(:valid_color) { Annotation.colors.values.first }

  before do
    # create_and_update_shared's valid_time? reads medium.video; stub it to
    # avoid real video processing. total_seconds/post_as_comment are required by
    # annotation_auxiliary_params (params.expect) — the real frontend sends them.
    allow_any_instance_of(Medium).to receive(:video).and_return("duration" => 100)
  end

  def edit_params(comment)
    { annotation: { comment: comment, color: valid_color,
                    total_seconds: "10", post_as_comment: "0" } }
  end

  describe "GET /annotations" do
    it "lists an annotation on a medium that hangs off a course" do
      course_medium = create(:course_medium)
      create(:annotation, medium_id: course_medium.id, user_id: owner.id,
                          comment: "on a course medium", category: :note)
      sign_in owner

      get annotations_path

      expect(response).to have_http_status(:ok)
      # The heading is escaped on its way into the page, and a course title can
      # carry an apostrophe.
      expect(response.body).to include(ERB::Util.html_escape(course_medium.teachable.title))
    end

    it "keeps both when a course and a lecture share their heading" do
      course_medium = create(:course_medium)
      course = course_medium.teachable
      course.update!(term_independent: true)
      lecture = create(:lecture, course: course, term: nil)
      lecture_medium = create(:valid_medium, teachable: lecture)
      create(:annotation, medium_id: course_medium.id, user_id: owner.id,
                          comment: "on the course", category: :note)
      create(:annotation, medium_id: lecture_medium.id, user_id: owner.id,
                          comment: "on the lecture", category: :note)
      sign_in owner

      get annotations_path

      expect(response.body).to include("on the course", "on the lecture")
    end

    it "leaves out an annotation on a medium that belongs to nothing" do
      orphan = create(:medium, :with_description, teachable: nil, sort: "RandomQuiz")
      create(:annotation, medium_id: orphan.id, user_id: owner.id,
                          comment: "on nothing at all", category: :note)
      sign_in owner

      get annotations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("on nothing at all")
    end
  end

  describe "an annotation owned by another user" do
    let!(:annotation) do
      create(:annotation, medium_id: medium.id, user_id: owner.id,
                          comment: "original", category: :note)
    end

    describe "PATCH /annotations/:id" do
      it "lets the owner rewrite their own annotation" do
        sign_in owner
        patch annotation_path(annotation, format: :js), params: edit_params("owner-edit")
        expect(annotation.reload.comment).to eq("owner-edit")
      end

      it "does not let another user rewrite it" do
        sign_in other_user
        patch annotation_path(annotation, format: :js), params: edit_params("hacked")
        expect(annotation.reload.comment).to eq("original")
      end
    end

    describe "GET /annotations/:id/edit" do
      # xhr: true mirrors the thyme $.ajax call; a GET rendering a .js template
      # requires it (Rails cross-origin-JS protection).
      it "returns the edit form to the owner" do
        sign_in owner
        get edit_annotation_path(annotation, format: :js), xhr: true
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to eq("false")
      end

      it "answers another user with json:false and does not leak the comment" do
        sign_in other_user
        get edit_annotation_path(annotation, format: :js), xhr: true
        expect(response.body.strip).to eq("false")
        expect(response.body).not_to include("original")
      end
    end

    describe "DELETE /annotations/:id" do
      it "lets the owner delete their own annotation" do
        sign_in owner
        expect { delete(annotation_path(annotation, format: :js)) }
          .to change(Annotation, :count).by(-1)
      end

      it "does not let another user delete it" do
        sign_in other_user
        expect { delete(annotation_path(annotation, format: :js)) }
          .not_to change(Annotation, :count)
      end
    end
  end

  describe "POST /annotations" do
    it "creates the annotation owned by the current user" do
      sign_in owner
      expect do
        post(annotations_path(format: :js), params: {
               annotation: { medium_id: medium.id, comment: "mine", color: valid_color,
                             category: "note", total_seconds: "10", post_as_comment: "0" }
             })
      end.to change(Annotation, :count).by(1)
      expect(Annotation.last.user_id).to eq(owner.id)
    end
  end

  describe "GET /annotations/update_annotations" do
    let(:medium_editor) { create(:confirmed_user) }
    let(:author) { create(:confirmed_user) }
    let(:viewer) { create(:confirmed_user) }
    let!(:shared) do
      create(:annotation, :shared_with_teacher, :with_text,
             medium_id: medium.id, user_id: author.id)
    end
    let!(:own) do
      create(:annotation, :with_text, medium_id: medium.id, user_id: viewer.id)
    end

    before { medium.editors << medium_editor }

    def returned_ids
      response.parsed_body.pluck("id")
    end

    it "returns only the caller's own annotations to a non-editor" do
      sign_in viewer
      get update_annotations_path, params: { mediumId: medium.id }
      expect(returned_ids).to include(own.id)
      expect(returned_ids).not_to include(shared.id)
    end

    it "returns teacher-visible annotations to a medium editor" do
      sign_in medium_editor
      get update_annotations_path, params: { mediumId: medium.id }
      expect(returned_ids).to include(shared.id)
    end
  end
end
