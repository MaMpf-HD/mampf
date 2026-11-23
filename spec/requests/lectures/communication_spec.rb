require "rails_helper"

RSpec.describe("Lecture forum and comments", type: :request) do
  let(:editor) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :with_forum) }
  let(:forum) { lecture.forum }
  let(:medium) do
    create(:lecture_medium, :with_lecture_by_id, lecture_id: lecture.id)
  end
  let(:communication_tab) { "#{edit_lecture_path(lecture)}?tab=communication" }

  before { create(:editable_user_join, user: editor, editable: lecture) }

  # The including group names the button's request with `path` and `perform`,
  # and with `state` what that request changes.
  shared_examples "a change only editors make, and not with GET" do
    it "brings the editor back to the communication tab" do
      sign_in editor

      perform

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(communication_tab)
    end

    it "changes nothing on GET" do
      sign_in editor

      expect { get(path) }.not_to(change { state })
      expect(flash[:alert]).to eq(I18n.t("controllers.no_page"))
    end

    it "changes nothing for a user who may not edit the lecture" do
      sign_in create(:confirmed_user)

      expect { perform }.not_to(change { state })
      expect(flash[:alert]).to eq(I18n.t("unauthorized.default"))
    end
  end

  describe "PATCH /lectures/:id/add_forum" do
    let(:lecture) { create(:lecture) }
    let(:path) { add_forum_path(lecture) }

    def perform = patch(path)
    def state = lecture.reload.forum_id

    it "gives the lecture a forum" do
      sign_in editor

      expect { perform }.to change(Thredded::Messageboard, :count).by(1)
      expect(lecture.reload.forum).to be_present
    end

    it_behaves_like "a change only editors make, and not with GET"
  end

  describe "PATCH /lectures/:id/lock_forum" do
    let(:path) { lock_forum_path(lecture) }

    def perform = patch(path)
    def state = forum.reload.locked

    it "locks the forum" do
      sign_in editor

      expect { perform }.to change { state }.from(false).to(true)
    end

    it_behaves_like "a change only editors make, and not with GET"
  end

  describe "PATCH /lectures/:id/unlock_forum" do
    let(:path) { unlock_forum_path(lecture) }

    before { forum.update!(locked: true) }

    def perform = patch(path)
    def state = forum.reload.locked

    it "unlocks the forum" do
      sign_in editor

      expect { perform }.to change { state }.from(true).to(false)
    end

    it_behaves_like "a change only editors make, and not with GET"
  end

  describe "DELETE /lectures/:id/destroy_forum" do
    let(:path) { destroy_forum_path(lecture) }

    def perform = delete(path)
    def state = Thredded::Messageboard.exists?(forum.id)

    it "deletes the forum" do
      sign_in editor

      expect { perform }.to change { state }.from(true).to(false)
      expect(lecture.reload.forum?).to be(false)
    end

    it_behaves_like "a change only editors make, and not with GET"
  end

  describe "PATCH /lectures/:id/close_comments" do
    let(:path) { lecture_close_comments_path(lecture) }

    before { medium }

    def perform = patch(path)
    def state = medium.commontator_thread.reload.is_closed?

    it "closes the comments of the lecture's media" do
      sign_in editor

      expect { perform }.to change { state }.from(false).to(true)
    end

    it_behaves_like "a change only editors make, and not with GET"
  end

  describe "PATCH /lectures/:id/open_comments" do
    let(:path) { lecture_open_comments_path(lecture) }

    before { medium.commontator_thread.close(editor) }

    def perform = patch(path)
    def state = medium.commontator_thread.reload.is_closed?

    it "reopens the comments of the lecture's media" do
      sign_in editor

      expect { perform }.to change { state }.from(true).to(false)
    end

    it_behaves_like "a change only editors make, and not with GET"
  end
end
