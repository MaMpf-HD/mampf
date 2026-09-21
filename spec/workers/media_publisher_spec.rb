require "rails_helper"

RSpec.describe(MediaPublisher) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:user) { create(:confirmed_user) }

  def schedule(release_date:)
    medium = create(:medium, :with_description, :with_editors, sort: "Exercise",
                                                               teachable: lecture)
    medium.editors << user
    medium.update!(publisher: MediumPublisher.new(medium_id: medium.id, user_id: user.id,
                                                  release_now: false,
                                                  release_date: release_date,
                                                  create_assignment: true,
                                                  assignment_title: "Blatt 3",
                                                  assignment_deadline: 2.weeks.from_now,
                                                  assignment_file_type: ".pdf",
                                                  requires_submission: false))
    medium
  end

  # A scheduled release must give the sheet the same pointbook an immediate one does.
  it "publishes a medium whose time has come, and makes its sheet with the pointbook" do
    medium = schedule(release_date: 1.hour.ago)

    described_class.new.perform

    expect(medium.reload.released).to eq("all")
    expect(medium.publisher).to be_nil
    assignment = lecture.assignments.find_by(title: "Blatt 3")
    expect(assignment.medium).to eq(medium)
    expect(assignment.assessment.requires_submission).to be(false)
  end

  it "leaves a medium alone whose time has not come" do
    medium = schedule(release_date: 1.hour.from_now)

    described_class.new.perform

    expect(medium.reload.released).to be_nil
    expect(medium.publisher).to be_present
    expect(lecture.assignments).to be_empty
  end
end
