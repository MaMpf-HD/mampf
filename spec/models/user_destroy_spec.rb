require "rails_helper"

# What a deleted account takes along that is not one of the person's
# contributions: their notes, notifications, read marks and likes.
RSpec.describe(User) do
  let(:user) { create(:confirmed_user) }
  let(:medium) { create(:lecture_medium) }

  it "deletes the user's annotations" do
    create(:annotation, user_id: user.id, medium_id: medium.id)

    expect { user.destroy! }.to change(Annotation, :count).by(-1)
  end

  # The talk media go before anything else of the account, and a medium
  # cannot go while notes point to it - the user's or anybody else's.
  it "deletes an account whose own talk medium carries annotations" do
    talk_medium = create(:talk_medium)
    talk_medium.editors = [user]
    create(:annotation, user_id: user.id, medium_id: talk_medium.id)
    create(:annotation, user_id: create(:confirmed_user).id, medium_id: talk_medium.id)

    expect { user.destroy! }.to change(Annotation, :count).by(-2)
    expect(Medium.exists?(talk_medium.id)).to be(false)
  end

  it "deletes the user's notifications and read marks" do
    create(:notification, recipient: user)
    create(:reader, user: user, thread: medium.commontator_thread)

    expect { user.destroy! }
      .to change(Notification, :count).by(-1).and(change(Reader, :count).by(-1))
  end

  it "takes back the user's likes and corrects the comment's like count" do
    author = create(:confirmed_user)
    comment = Commontator::Comment.create!(thread: medium.commontator_thread,
                                           creator: author, body: Faker::Lorem.sentence)
    comment.upvote_from(user)
    comment.upvote_from(create(:confirmed_user))

    user.destroy!

    expect(ActsAsVotable::Vote.where(voter_id: user.id, voter_type: "User")).to be_empty
    expect(comment.reload.cached_votes_up).to eq(1)
  end
end
