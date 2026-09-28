require "rails_helper"

# The comments page must list every thread whose notice reached the user;
# the notice goes to the lecture's audience (see LectureAudience).
RSpec.describe(User) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:student) { create(:confirmed_user) }
  let(:author) { create(:confirmed_user) }

  def commented(medium)
    medium.update!(released: "all", released_at: Time.zone.now)
    Commontator::Comment.create!(thread: medium.commontator_thread, creator: author,
                                 body: Faker::Lorem.sentence)
    medium
  end

  it "lists a lecture's commented media for a student whose only tie is a registration" do
    medium = commented(create(:lecture_medium, teachable: lecture))
    campaign = create(:registration_campaign, :open, :with_items, campaignable: lecture)
    create(:registration_user_registration, :pending,
           user: student, registration_campaign: campaign,
           registration_item: campaign.registration_items.first)

    expect(student.subscribed_commentable_media_with_comments).to include(medium)
  end

  it "lists commented talk media too" do
    medium = create(:talk_medium)
    medium.teachable.lecture.update!(released: "all")
    commented(medium)
    student.bookmark_lecture!(medium.teachable.lecture)

    expect(student.subscribed_commentable_media_with_comments).to include(medium)
  end

  it "leaves out the media of a lecture the student only reads" do
    commented(create(:lecture_medium, teachable: lecture))

    expect(student.subscribed_commentable_media_with_comments).to be_empty
  end
end
