require "rails_helper"

# Commontator's own controllers answer these requests. They do not load the
# app's helpers, so the comment views have to reach them on their own.
RSpec.describe("Comments", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:medium) do
    create(:lecture_medium, released: "all", released_at: Time.zone.now)
  end
  let(:comment) do
    Commontator::Comment.create!(
      thread: medium.commontator_thread, creator: user,
      body: 'A <b class="big">bold</b> word and <img src="x.png"> more'
    )
  end

  before { sign_in user }

  describe "GET /commontator/comments/:id" do
    it "shows the comment with the formatting of a comment" do
      get commontator.comment_path(comment), xhr: true

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<p>A <b>bold<\/b> word and  more<\/p>')
    end
  end

  describe "GET /commontator/comments/:id/edit" do
    it "previews the comment with the formatting of a comment" do
      get commontator.edit_comment_path(comment), xhr: true

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<p>A <b>bold<\/b> word and  more<\/p>')
    end
  end
end
