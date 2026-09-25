require "rails_helper"

# A medium released to "only participants" (`released: "subscribers"`) is for
# the lecture's audience: who bookmarked it, sits on one of its rosters or has
# a registration running; a course medium, for the audience of one of the
# course's lectures.
RSpec.describe(Medium) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:student) { create(:confirmed_user) }
  let(:lecture_medium) { participants_only(create(:lecture_medium, teachable: lecture)) }
  let(:course_medium) { participants_only(create(:course_medium, teachable: lecture.course)) }

  def participants_only(medium)
    medium.update!(released: "subscribers", released_at: Time.zone.now)
    medium
  end

  def visible
    student.filter_visible_media(Medium.where(id: [lecture_medium.id, course_medium.id]))
  end

  it "is hidden from a student who only reads the open lecture" do
    expect(lecture_medium.visible_for_user?(student)).to be(false)
    expect(course_medium.visible_for_user?(student)).to be(false)
    expect(visible).to be_empty
  end

  it "is shown to a student who bookmarked the lecture" do
    student.bookmark_lecture!(lecture)

    expect(lecture_medium.visible_for_user?(student)).to be(true)
    expect(course_medium.visible_for_user?(student)).to be(true)
    expect(visible).to contain_exactly(lecture_medium, course_medium)
  end

  it "is shown to a member of a tutorial of the lecture" do
    create(:tutorial, lecture: lecture).add_user_to_roster!(student)

    expect(lecture_medium.visible_for_user?(student)).to be(true)
    expect(visible).to include(lecture_medium)
  end

  it "is shown to a student with a registration still running" do
    campaign = create(:registration_campaign, :open, :with_items, campaignable: lecture)
    create(:registration_user_registration, :pending,
           user: student, registration_campaign: campaign,
           registration_item: campaign.registration_items.first)

    expect(lecture_medium.visible_for_user?(student)).to be(true)
    expect(visible).to include(lecture_medium)
  end

  it "leaves media for registered users open to every student" do
    lecture_medium.update!(released: "users")

    expect(lecture_medium.visible_for_user?(student)).to be(true)
    expect(visible).to include(lecture_medium)
  end
end
