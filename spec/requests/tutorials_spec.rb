require "rails_helper"

RSpec.describe("Tutorials", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let!(:tutorial) { create(:tutorial, lecture: lecture) }

  before do
    create(:editable_user_join, user: editor, editable: lecture)
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
end
