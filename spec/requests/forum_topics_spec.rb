require "rails_helper"

RSpec.describe("Forum topics", type: :request) do
  let(:student) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :with_forum, :released_for_all) }
  let(:forum) { Thredded::Messageboard.find(lecture.forum_id) }

  before { sign_in student }

  describe "POST /forum/:messageboard_id" do
    it "creates the first topic of a student who has never posted" do
      expect do
        post(thredded.messageboard_topics_path(forum),
             params: { topic: { title: "Exercise 3", content: "Any hints?" } })
      end.to change(Thredded::Topic, :count).by(1)

      expect(response).to redirect_to(thredded.messageboard_topics_path(forum))
      topic = Thredded::Topic.last
      expect(topic.posts.pluck(:content)).to eq(["Any hints?"])
      expect(Thredded::UserDetail.find_by!(user: student))
        .to have_attributes(topics_count: 1, posts_count: 1)
    end

    it "shows the form again with an error for a blank title" do
      expect do
        post(thredded.messageboard_topics_path(forum),
             params: { topic: { title: "", content: "Any hints?" } })
      end.not_to change(Thredded::Topic, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("thredded--alert-danger")
    end
  end
end
