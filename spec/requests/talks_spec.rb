require "rails_helper"

RSpec.describe("Talks", type: :request) do
  describe "editor actions" do
    let(:lecture) { create(:seminar) }
    let(:editor) { create(:confirmed_user) }
    let!(:talk) { create(:talk, lecture: lecture) }

    before do
      create(:editable_user_join, user: editor, editable: lecture)
      sign_in editor
    end

    describe "GET /talks/new" do
      it "returns http success" do
        get new_talk_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /talks" do
      let(:valid_attributes) do
        { title: "New Talk", capacity: 25, lecture_id: lecture.id }
      end
      let(:invalid_attributes) do
        { title: "", capacity: -1, lecture_id: lecture.id }
      end

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

    describe "GET /talks/:id/edit" do
      it "returns http success" do
        get edit_talk_path(talk), as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    describe "DELETE /talks/:id" do
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

    describe "PATCH /talks/:id" do
      let(:valid_attributes) { { title: "Updated Talk", capacity: 30 } }

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

  describe "GET /talks/:id" do
    let(:user) { create(:confirmed_user) }
    let(:lecture) { create(:seminar, teacher: user) }
    let(:talk) do
      create(:valid_talk,
             lecture: lecture,
             details: "<script>alert('xss-details')</script>",
             description: "<script>alert('xss-description')</script>",
             display_description: true)
    end

    before do
      allow_any_instance_of(ActionView::Base)
        .to receive(:vite_stylesheet_tag).and_return("")
      allow_any_instance_of(ActionView::Base)
        .to receive(:vite_client_tag).and_return("")
      allow_any_instance_of(ActionView::Base)
        .to receive(:vite_javascript_tag).and_return("")
      sign_in user
    end

    it "escapes or strips script tags in the talk details and description" do
      get talk_path(talk)
      expect(response).to be_successful
      expect(response.body).not_to include("<script>alert('xss-details')</script>")
      expect(response.body).not_to include("<script>alert('xss-description')</script>")
    end
  end
end
