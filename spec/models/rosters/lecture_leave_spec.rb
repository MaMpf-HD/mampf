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

  # Puts the group into an open campaign. update_column skips the check that
  # only groups with an empty roster join a campaign.
  def hold_in_campaign(group)
    group.update_column(:skip_campaigns, false) # rubocop:disable Rails/SkipsModelValidations
    campaign = create(:registration_campaign, campaignable: lecture)
    create(:registration_item, registration_campaign: campaign, registerable: group)
    campaign.update!(status: :open)
  end

  # Sets the status with update_columns: the regular transitions would need
  # dates and items this spec doesn't set up.
  def exam_campaign(status, title: "Final exam", deadline: nil)
    campaign = create(:exam, lecture: lecture, title: title).registration_campaign
    deadline ||= status == :open ? 1.week.from_now : 1.day.ago
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

    it "is true with a registration past its withdrawal, before any place" do
      campaign = create(:registration_campaign, :closed, campaignable: lecture)
      create(:registration_user_registration, :pending,
             user: student, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      expect(leave.participating?).to be(true)
    end

    it "is true with only a rejected registration past its withdrawal" do
      campaign = create(:registration_campaign, :processing, campaignable: lecture)
      registration = create(:registration_user_registration, :rejected,
                            user: student, registration_campaign: campaign,
                            registration_item: campaign.registration_items.first)

      expect(leave.participating?).to be(true)
      expect(leave.campaigns_to_withdraw).to be_empty

      leave.leave!
      expect { registration.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "is false with a registration its campaign still lets the student withdraw" do
      campaign = create(:registration_campaign, :open, campaignable: lecture)
      create(:registration_user_registration, :pending,
             user: student, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      expect(leave.participating?).to be(false)
    end
  end

  describe "#blockers" do
    before { lecture.add_user_to_roster!(student) }

    it "is empty for groups their members may leave" do
      leavable_tutorial.add_user_to_roster!(student)
      create(:cohort, :enrollment, context: lecture, skip_campaigns: true,
                                   self_materialization_mode: :remove_only)
        .add_user_to_roster!(student)

      expect(leave.blockers).to be_empty
      expect(leave.allowed?).to be(true)
    end

    it "names a tutorial or cohort its members may not leave, and offers the staff" do
      create(:tutorial, lecture: lecture, title: "Mo 10", skip_campaigns: true,
                        self_materialization_mode: :disabled).add_user_to_roster!(student)
      create(:cohort, :enrollment, context: lecture, title: "Repeaters", skip_campaigns: true,
                                   self_materialization_mode: :add_only)
        .add_user_to_roster!(student)

      expect(leave.blockers.map(&:to_a))
        .to eq([[:group_held, "Mo 10", true], [:group_held, "Repeaters", true]])
      expect(leave.allowed?).to be(false)
    end

    it "ignores the setting of a cohort without enrollment" do
      create(:cohort, context: lecture, skip_campaigns: true,
                      self_materialization_mode: :disabled).add_user_to_roster!(student)

      expect(leave.blockers).to be_empty
    end

    it "names a group still held by a campaign, and offers the staff" do
      fixed = create(:tutorial, lecture: lecture, title: "Mo 10", skip_campaigns: true)
      fixed.add_user_to_roster!(student)
      hold_in_campaign(fixed)

      expect(leave.blockers.map(&:to_a)).to eq([[:group_held, "Mo 10", true]])
      expect(leave.allowed?).to be(false)
    end

    it "is empty for a group of a completed campaign its members may leave" do
      group = leavable_tutorial
      group.add_user_to_roster!(student)
      hold_in_campaign(group)
      group.registration_items.first.registration_campaign
           .update_column(:status, Registration::Campaign.statuses[:completed]) # rubocop:disable Rails/SkipsModelValidations

      expect(leave.blockers).to be_empty
    end

    it "names a talk its speakers may not leave" do
      seminar = create(:lecture, :is_seminar, :released_for_all)
      talk = create(:talk, lecture: seminar, skip_campaigns: true,
                           self_materialization_mode: :add_only)
      talk.add_user_to_roster!(student)

      expect(described_class.new(seminar, student).blockers.map(&:to_a))
        .to eq([[:group_held, talk.to_label, true]])
    end

    it "names a graded exam without offering the staff" do
      exam = create(:exam, :without_campaign, lecture: lecture, title: "Final exam")
      exam.add_user_to_roster!(student)
      grade!(exam)

      expect(leave.blockers.map(&:to_a)).to eq([[:graded, "Final exam", false]])
    end

    it "names only the graded exam when a group could not be left either" do
      fixed = create(:tutorial, lecture: lecture, skip_campaigns: true)
      fixed.add_user_to_roster!(student)
      hold_in_campaign(fixed)
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

    it "names an open exam registration whose deadline has passed" do
      campaign = exam_campaign(:open, deadline: 1.minute.ago)
      create(:registration_user_registration, :confirmed,
             user: student, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      expect(leave.blockers.map(&:to_a)).to eq([[:exam_closed, "Final exam", true]])
      expect(leave.campaigns_to_withdraw).to be_empty
    end

    it "names a registration elsewhere that requires one leaving withdraws" do
      tutorials = create(:registration_campaign, :open, campaignable: lecture)
      create(:registration_user_registration, :pending,
             user: student, registration_campaign: tutorials,
             registration_item: tutorials.registration_items.first)
      # Policies can only be added while the campaign is a draft.
      seminar = create(:registration_campaign, :open, description: "Seminar")
      seminar.update_column(:status, Registration::Campaign.statuses[:draft]) # rubocop:disable Rails/SkipsModelValidations
      create(:registration_policy, :prerequisite_campaign,
             registration_campaign: seminar,
             config: { "prerequisite_campaign_id" => tutorials.id })
      seminar.update_column(:status, Registration::Campaign.statuses[:open]) # rubocop:disable Rails/SkipsModelValidations
      create(:registration_user_registration, :confirmed,
             user: student, registration_campaign: seminar,
             registration_item: seminar.registration_items.first)

      expect(leave.blockers.map(&:to_a))
        .to eq([[:prerequisite, seminar.student_facing_title, true]])
    end

    it "names a graded talk once, though its speakers may not leave it either" do
      seminar = create(:lecture, :is_seminar, :released_for_all)
      talk = create(:talk, lecture: seminar, title: "Groups")
      talk.add_user_to_roster!(student)
      grade!(talk)

      expect(described_class.new(seminar, student).blockers.map(&:reason)).to eq([:graded])
    end
  end

  describe "#campaigns_to_withdraw" do
    it "lists running registrations, an open exam registration among them" do
      lecture.add_user_to_roster!(student)
      tutorials = create(:registration_campaign, :closed, campaignable: lecture)
      exam = exam_campaign(:open)
      [tutorials, exam].each do |campaign|
        create(:registration_user_registration, :pending,
               user: student, registration_campaign: campaign,
               registration_item: campaign.registration_items.first)
      end

      expect(leave.campaigns_to_withdraw).to contain_exactly(tutorials, exam)
      expect(leave.blockers).to be_empty
    end
  end

  describe "#only_place?" do
    let(:mo) { leavable_tutorial }
    let(:list) { create(:cohort, context: lecture, propagate_to_lecture: false) }

    before do
      lecture.add_user_to_roster!(student)
      mo.add_user_to_roster!(student)
    end

    it "is true for the last group with enrollment, even beside a list" do
      list.add_user_to_roster!(student)

      expect(described_class.new(lecture, student).only_place?(mo)).to be(true)
      expect(described_class.new(lecture, student).only_place?(list)).to be(false)
    end

    it "is false while another group with enrollment remains" do
      create(:cohort, :enrollment, context: lecture).add_user_to_roster!(student)

      expect(described_class.new(lecture, student).only_place?(mo)).to be(false)
    end

    it "agrees with only_place_user_ids for a whole roster" do
      other = create(:confirmed_user)
      lecture.add_user_to_roster!(other)
      mo.add_user_to_roster!(other)
      create(:cohort, :enrollment, context: lecture).add_user_to_roster!(other)

      expect(described_class.only_place_user_ids(mo, [student.id, other.id]))
        .to contain_exactly(student.id)
      expect(described_class.only_place_user_ids(list, [student.id])).to be_empty
    end
  end

  describe "#admitted?" do
    it "is true for a granted admission, computed or by hand" do
      certification = create(:student_performance_certification, :passed,
                             lecture: lecture, user: student)
      expect(leave.admitted?).to be(true)

      certification.update!(source: :manual, note: "Medical certificate")
      expect(described_class.new(lecture, student).admitted?).to be(true)
    end

    it "is false for a refused admission" do
      create(:student_performance_certification, :failed, lecture: lecture, user: student)

      expect(leave.admitted?).to be(false)
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
      expect(lecture.members).not_to include(student)
      expect(lecture.excluded_lecture_memberships.find_by(user: student)).to be_left_by_self
      expect(campaign.user_registrations.where(user: student)).to be_empty
      expect(student.reload.lectures).not_to include(lecture)
    end

    it "withdraws a registration past its deadline for someone with no place yet" do
      lecture.lecture_memberships.find_by(user: student).destroy!
      tutorial.remove_user_from_roster!(student)
      campaign = create(:registration_campaign, :closed, campaignable: lecture)
      create(:registration_user_registration, :pending,
             user: student, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      described_class.new(lecture, student).leave!

      expect(campaign.user_registrations.where(user: student)).to be_empty
      expect(student.reload.lectures).not_to include(lecture)
    end

    it "withdraws a rejected registration too, which a new allocation would revive" do
      campaign = create(:registration_campaign, :processing, campaignable: lecture)
      create(:registration_user_registration, :rejected,
             user: student, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      leave.leave!

      expect(campaign.user_registrations.where(user: student)).to be_empty
    end

    it "keeps the exam admission for a return" do
      admission = create(:student_performance_certification, :passed, :manual,
                         lecture: lecture, user: student)

      leave.leave!

      expect(admission.reload).to be_passed
    end

    it "decides again under the locks when a group changed after the check" do
      expect(leave.allowed?).to be(true)
      hold_in_campaign(tutorial)

      expect { leave.leave! }.to raise_error(described_class::NotAllowedError)
      expect(tutorial.reload.members).to include(student)
    end

    it "says the student takes part no more when the staff removed them meanwhile" do
      expect(leave.allowed?).to be(true)
      Rosters::MaintenanceService.new.remove_user!(student, lecture, notify: false)

      expect { leave.leave! }.to raise_error(described_class::NotParticipatingError)
    end

    it "locks the groups before the lecture, and the lecture before any membership goes" do
      membership_at_lock = nil
      allow(lecture).to receive(:lock!).and_wrap_original do |original, *args|
        membership_at_lock = TutorialMembership.exists?(user: student)
        original.call(*args)
      end

      models = locked_models { leave.leave! }

      expect(models.index(Tutorial)).to be < models.index(Lecture)
      expect(membership_at_lock).to be(true)
    end

    it "locks a tutorial before a cohort, as the bulk self-service setting does" do
      create(:cohort, context: lecture, skip_campaigns: true).add_user_to_roster!(student)

      models = locked_models { leave.leave! }

      expect(models.index(Tutorial)).to be < models.index(Cohort)
    end

    it "locks an exam the student is listed for before the lecture" do
      create(:exam, :without_campaign, lecture: lecture).add_user_to_roster!(student)

      models = locked_models do
        leave.leave!
      rescue described_class::NotAllowedError
        nil
      end

      expect(models.index(Exam)).to be < models.index(Lecture)
    end

    it "refuses rather than fails when a grade arrives while leaving" do
      places = instance_double(Rosters::UserPlaces)
      allow(Rosters::UserPlaces).to receive(:new).and_return(places)
      allow(places).to receive(:leave!)
        .and_raise(Rosters::MaintenanceService::GradingDataPresentError)

      expect { leave.leave! }.to raise_error(described_class::NotAllowedError)
      expect(student.reload.lectures).to include(lecture)
    end

    it "tries once more after a deadlock" do
      places = instance_double(Rosters::UserPlaces)
      allow(Rosters::UserPlaces).to receive(:new).and_return(places)
      calls = 0
      allow(places).to receive(:leave!) do
        calls += 1
        raise(ActiveRecord::Deadlocked) if calls == 1
      end

      leave.leave!

      expect(calls).to eq(2)
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
      hold_in_campaign(tutorial)

      expect { leave.leave! }.to raise_error(described_class::NotAllowedError)
      expect(tutorial.reload.members).to include(student)
      expect(lecture.members).to include(student)
    end
  end
end
