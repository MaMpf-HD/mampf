require "rails_helper"

RSpec.describe(Rosters::LectureLeave) do
  let(:student) { create(:confirmed_user) }
  let(:grader) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:leave) { described_class.new(lecture, student) }

  def leavable_tutorial
    create(:tutorial, lecture: lecture, skip_campaigns: true,
                      self_materialization_mode: :add_and_remove)
  end

  # An exam opens its own registration process; the status is set past the
  # transitions, which would ask for dates and items this spec does not need.
  def exam_campaign(status, title: "Final exam")
    campaign = create(:exam, lecture: lecture, title: title).registration_campaign
    deadline = status == :open ? 1.week.from_now : 1.day.ago
    campaign.update_columns(status: Registration::Campaign.statuses[status], # rubocop:disable Rails/SkipsModelValidations
                            registration_deadline: deadline)
    campaign
  end

  def grade!(gradable)
    gradable.ensure_assessment!(requires_points: false)
    Assessment::Participation.create!(assessment: gradable.assessment, user: student)
                             .update!(grade_numeric: 2.0, grader: grader,
                                      graded_at: Time.current, status: :reviewed)
  end

  describe "#participating?" do
    it "is false without a place in the lecture" do
      expect(leave.participating?).to be(false)
    end

    it "is true on the lecture roster, in a group or on an exam list" do
      [lecture, create(:tutorial, lecture: lecture),
       create(:exam, lecture: lecture)].each do |rosterable|
        rosterable.add_user_to_roster!(student)
        expect(described_class.new(lecture, student).participating?)
          .to be(true), rosterable.class.name
        rosterable.remove_user_from_roster!(student)
      end
    end
  end

  describe "#blockers" do
    before { lecture.add_user_to_roster!(student) }

    it "is empty for a tutorial that lets its members leave" do
      leavable_tutorial.add_user_to_roster!(student)

      expect(leave.blockers).to be_empty
      expect(leave.allowed?).to be(true)
    end

    it "names a group the student may not leave, and offers the staff" do
      fixed = create(:tutorial, lecture: lecture, title: "Mo 10", skip_campaigns: true,
                                self_materialization_mode: :add_only)
      fixed.add_user_to_roster!(student)

      expect(leave.blockers.map(&:to_a)).to eq([[:group_fixed, "Mo 10", true]])
      expect(leave.allowed?).to be(false)
    end

    it "names a graded exam without offering the staff" do
      exam = create(:exam, :without_campaign, lecture: lecture, title: "Final exam")
      exam.add_user_to_roster!(student)
      grade!(exam)

      expect(leave.blockers.map(&:to_a)).to eq([[:graded, "Final exam", false]])
    end

    it "names only the graded exam when a group could not be left either" do
      create(:tutorial, lecture: lecture, skip_campaigns: true,
                        self_materialization_mode: :add_only).add_user_to_roster!(student)
      exam = create(:exam, :without_campaign, lecture: lecture, title: "Midterm")
      exam.add_user_to_roster!(student)
      grade!(exam)

      expect(leave.blockers.map(&:to_a)).to eq([[:graded, "Midterm", false]])
    end

    it "names an ungraded exam list, which only the staff can change" do
      exam = create(:exam, :without_campaign, lecture: lecture, title: "Final exam")
      exam.add_user_to_roster!(student)

      expect(leave.blockers.map(&:to_a)).to eq([[:exam_closed, "Final exam", true]])
    end

    it "names an exam registration past its deadline" do
      campaign = exam_campaign(:closed)
      create(:registration_user_registration, :confirmed,
             user: student, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      expect(leave.blockers.map(&:to_a)).to eq([[:exam_closed, "Final exam", true]])
    end

    it "names a graded talk once, though its speakers may not leave it either" do
      seminar = create(:lecture, :is_seminar, :released_for_all)
      talk = create(:talk, lecture: seminar, title: "Groups")
      talk.add_user_to_roster!(student)
      grade!(talk)

      expect(described_class.new(seminar, student).blockers.map(&:reason)).to eq([:graded])
    end
  end

  describe "#withdrawn_campaigns" do
    it "lists running registrations, an open exam registration among them" do
      lecture.add_user_to_roster!(student)
      tutorials = create(:registration_campaign, :closed, campaignable: lecture)
      exam = exam_campaign(:open)
      [tutorials, exam].each do |campaign|
        create(:registration_user_registration, :pending,
               user: student, registration_campaign: campaign,
               registration_item: campaign.registration_items.first)
      end

      expect(leave.withdrawn_campaigns).to contain_exactly(tutorials, exam)
      expect(leave.blockers).to be_empty
    end
  end

  describe "#admission" do
    it "tells a computed admission from one granted by hand" do
      certification = create(:student_performance_certification, :passed,
                             lecture: lecture, user: student)
      expect(leave.admission).to eq(:computed)

      certification.update!(source: :manual, note: "Medical certificate")
      expect(described_class.new(lecture, student).admission).to eq(:manual)
    end

    it "is nil for a refused admission" do
      create(:student_performance_certification, :failed, lecture: lecture, user: student)

      expect(leave.admission).to be_nil
    end
  end

  describe "#leave!" do
    let(:tutorial) { leavable_tutorial }

    before do
      lecture.add_user_to_roster!(student)
      tutorial.add_user_to_roster!(student)
      student.bookmark_lecture!(lecture)
    end

    it "leaves the groups and the lecture, withdraws registrations and the bookmark" do
      campaign = exam_campaign(:open)
      create(:registration_user_registration, :pending,
             user: student, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      leave.leave!

      expect(tutorial.reload.members).not_to include(student)
      expect(LectureMembership.exists?(lecture: lecture, user: student)).to be(false)
      expect(campaign.user_registrations.where(user: student)).to be_empty
      expect(student.reload.lectures).not_to include(lecture)
    end

    it "keeps recorded points for a later return" do
      assignment = create(:assignment, lecture: lecture)
      assignment.ensure_pointbook!
      assignment.update_column(:deadline, 2.days.ago) # rubocop:disable Rails/SkipsModelValidations
      participation = Assessment::Participation.create!(
        assessment: assignment.assessment, user: student, tutorial: tutorial,
        points_total: 7, status: :reviewed, grader: grader, graded_at: Time.current
      )

      leave.leave!

      expect(participation.reload.points_total).to eq(7)
    end

    it "changes nothing when a blocker stands in the way" do
      tutorial.update!(self_materialization_mode: :add_only)

      expect { leave.leave! }.to raise_error(described_class::NotAllowedError)
      expect(tutorial.reload.members).to include(student)
      expect(LectureMembership.exists?(lecture: lecture, user: student)).to be(true)
    end
  end
end
