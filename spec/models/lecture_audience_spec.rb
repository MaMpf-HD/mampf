require "rails_helper"

RSpec.describe(LectureAudience) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:student) { create(:confirmed_user) }

  let(:audience) { lecture.audience }

  def register(user, campaign, status)
    create(:registration_user_registration, status,
           user: user, registration_campaign: campaign,
           registration_item: campaign.registration_items.first)
  end

  it "leaves out a student who only reads the open lecture" do
    student

    expect(audience).not_to include(student)
  end

  it "takes in who bookmarked it" do
    student.bookmark_lecture!(lecture)

    expect(audience).to include(student)
  end

  it "takes in who sits on a tutorial, cohort or exam list of it" do
    tutorial_member, cohort_member, exam_member = create_list(:confirmed_user, 3)
    create(:tutorial, lecture: lecture).add_user_to_roster!(tutorial_member)
    create(:cohort, context: lecture).add_user_to_roster!(cohort_member)
    create(:exam, lecture: lecture).add_user_to_roster!(exam_member)

    expect(audience).to include(tutorial_member, cohort_member, exam_member)
  end

  it "takes in a registration still running, but not a rejected or finished one" do
    running, rejected, finished = create_list(:confirmed_user, 3)
    open_campaign = create(:registration_campaign, :open, :with_items, campaignable: lecture)
    done = create(:registration_campaign, :completed, :with_items, campaignable: lecture)
    register(running, open_campaign, :pending)
    register(rejected, open_campaign, :rejected)
    register(finished, done, :confirmed)

    expect(audience).to include(running)
    expect(audience).not_to include(rejected, finished)
  end

  it "names everybody once, however many ways they belong" do
    student.bookmark_lecture!(lecture)
    lecture.add_user_to_roster!(student)

    expect(audience.where(id: student.id).count).to eq(1)
  end
end
