require "rails_helper"

RSpec.describe("Tutorials", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let!(:tutorial) { create(:tutorial, lecture: lecture) }

  before do
    create(:editable_user_join, user: editor, editable: lecture)
  end

  describe "GET /tutorials/new" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get new_tutorial_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /tutorials" do
    let(:valid_attributes) { { title: "New Tutorial", capacity: 25, lecture_id: lecture.id } }
    let(:invalid_attributes) { { title: "", capacity: -1, lecture_id: lecture.id } }

    context "as an editor" do
      before { sign_in editor }

      context "with valid parameters" do
        it "creates a new tutorial" do
          expect do
            post(tutorials_path,
                 params: { tutorial: valid_attributes },
                 as: :turbo_stream)
          end.to change(Tutorial, :count).by(1)
        end

        it "renders a successful response" do
          post tutorials_path,
               params: { tutorial: valid_attributes },
               as: :turbo_stream
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end
      end

      context "with invalid parameters" do
        it "does not create a new tutorial" do
          expect do
            post(tutorials_path,
                 params: { tutorial: invalid_attributes },
                 as: :turbo_stream)
          end.not_to change(Tutorial, :count)
        end

        it "renders an unprocessable_entity response" do
          post tutorials_path,
               params: { tutorial: invalid_attributes },
               as: :turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "GET /tutorials/:id/edit" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get edit_tutorial_path(tutorial), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /tutorials/:id" do
    let(:valid_attributes) { { title: "Updated Tutorial", capacity: 30 } }
    let(:invalid_attributes) { { title: "", capacity: -1 } }

    context "as an editor" do
      before { sign_in editor }

      context "with valid parameters" do
        it "updates the requested tutorial" do
          patch tutorial_path(tutorial),
                params: { tutorial: valid_attributes },
                as: :turbo_stream
          tutorial.reload
          expect(tutorial.title).to eq("Updated Tutorial")
        end

        it "renders a successful response" do
          patch tutorial_path(tutorial),
                params: { tutorial: valid_attributes },
                as: :turbo_stream
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end
      end

      context "with invalid parameters" do
        it "does not update the tutorial" do
          patch tutorial_path(tutorial),
                params: { tutorial: invalid_attributes },
                as: :turbo_stream
          tutorial.reload
          expect(tutorial.title).not_to eq("")
        end

        it "renders an unprocessable_entity response" do
          patch tutorial_path(tutorial),
                params: { tutorial: invalid_attributes },
                as: :turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "DELETE /tutorials/:id" do
    context "as an editor" do
      before { sign_in editor }

      it "destroys the requested tutorial" do
        expect do
          delete(tutorial_path(tutorial), as: :turbo_stream)
        end.to change(Tutorial, :count).by(-1)
      end

      it "renders a successful response" do
        delete tutorial_path(tutorial), as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end
    end
  end
end
