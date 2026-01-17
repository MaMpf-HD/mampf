require "rails_helper"

RSpec.describe("Talks", type: :request) do
  let(:lecture) { create(:seminar) }
  let(:editor) { create(:confirmed_user) }
  let!(:talk) { create(:talk, lecture: lecture) }

  before do
    create(:editable_user_join, user: editor, editable: lecture)
  end

  describe "GET /talks/new" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get new_talk_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /talks" do
    let(:valid_attributes) { { title: "New Talk", capacity: 25, lecture_id: lecture.id } }
    let(:invalid_attributes) { { title: "", capacity: -1, lecture_id: lecture.id } }

    context "as an editor" do
      before { sign_in editor }

      context "with valid parameters" do
        it "creates a new talk" do
          expect do
            post(talks_path,
                 params: { talk: valid_attributes },
                 as: :turbo_stream)
          end.to change(Talk, :count).by(1)
        end

        it "renders a successful response" do
          post talks_path,
               params: { talk: valid_attributes },
               as: :turbo_stream
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end
      end

      context "with invalid parameters" do
        it "does not create a new talk" do
          expect do
            post(talks_path,
                 params: { talk: invalid_attributes },
                 as: :turbo_stream)
          end.not_to change(Talk, :count)
        end

        it "renders an unprocessable_entity response" do
          post talks_path,
               params: { talk: invalid_attributes },
               as: :turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe "GET /talks/:id/edit" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get edit_talk_path(talk), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "DELETE /talks/:id" do
    context "as an editor" do
      before { sign_in editor }

      it "destroys the requested talk" do
        expect do
          delete(talk_path(talk), as: :turbo_stream)
        end.to change(Talk, :count).by(-1)
      end

      it "renders a successful response" do
        delete talk_path(talk), as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end
    end
  end

  describe "PATCH /talks/:id" do
    let(:valid_attributes) { { title: "Updated Talk", capacity: 30 } }

    context "as an editor" do
      before { sign_in editor }

      it "updates the requested talk" do
        patch talk_path(talk),
              params: { talk: valid_attributes },
              as: :turbo_stream
        talk.reload
        expect(talk.title).to eq("Updated Talk")
      end

      it "renders a successful response" do
        patch talk_path(talk),
              params: { talk: valid_attributes },
              as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end
    end
  end
end
