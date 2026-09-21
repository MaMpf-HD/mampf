require "rails_helper"

# The lecture this stages is the one the seat rule is measured against: what
# production carries from before the roster. So the shape is the claim.
RSpec.describe(Demo::LegacyLectureSupport, type: :model) do
  before do
    create(:term, active: true)
    create(:confirmed_user, email: "teacher@mampf.edu")
    create(:confirmed_user, email: "tutor@mampf.edu")
    create(:confirmed_user, email: "student1@mampf.edu")
    allow(Demo::HandInSupport).to receive(:manuscript_path).and_return("stub")
    allow(Demo::HandInSupport).to receive(:manuscript_copy) do
      File.open("#{SPEC_FILES}/manuscript.pdf", "rb")
    end
    allow($stdout).to receive(:puts)
  end

  let(:lecture) do
    Lecture.joins(:course).find_by(courses: { title: described_class::COURSE_TITLE })
  end

  it "builds a lecture that runs no roster, with groups nobody sits in" do
    described_class.setup!

    expect(lecture.roster_managed?).to be(false)
    expect(lecture.tutorials.count).to eq(2)
    expect(TutorialMembership.joins(:tutorial)
                             .where(tutorials: { lecture_id: lecture.id })).to be_empty
  end

  it "hands in the old way: a group on the submission, no seat, no pointbook" do
    described_class.setup!
    submissions = Submission.joins(:assignment)
                            .where(assignments: { lecture_id: lecture.id })

    expect(submissions).to be_present
    expect(submissions.map(&:tutorial).uniq.size).to eq(2)
    expect(lecture.assignments.map(&:assessment)).to all(be_nil)
    student = User.find_by(email: "student1@mampf.edu")
    expect(student.rostered_tutorial_in(lecture)).to be_nil
    expect(lecture.in?(student.lectures)).to be(true)
  end

  it "leaves the sheet still running without a hand-in" do
    described_class.setup!
    open_sheet = lecture.assignments.find_by(title: "Legacy Sheet 3")

    expect(open_sheet.deadline).to be_future
    expect(open_sheet.submissions).to be_empty
  end

  it "can be run again without doubling anything" do
    described_class.setup!
    described_class.setup!

    expect(Lecture.joins(:course)
                  .where(courses: { title: described_class::COURSE_TITLE }).count).to eq(1)
    expect(lecture.tutorials.count).to eq(2)
    expect(lecture.assignments.count).to eq(3)
    expect(User.where("email LIKE 'legacy-student-%'").count)
      .to eq(described_class::GENERATED_STUDENTS)
  end
end
