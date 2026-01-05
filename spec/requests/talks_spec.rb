require "rails_helper"

RSpec.describe("Talks", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let!(:talk) { create(:talk, lecture: lecture) }

  before do
    create(:editable_user_join, user: editor, editable: lecture)
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
