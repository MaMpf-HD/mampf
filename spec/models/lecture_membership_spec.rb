require "rails_helper"

RSpec.describe(LectureMembership, type: :model) do
  it "has a valid factory" do
    expect(build(:lecture_membership)).to be_valid
  end

  describe "performance record callbacks" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:user) { FactoryBot.create(:confirmed_user) }

    it "creates a performance record when a membership is created" do
      service = instance_double(
        StudentPerformance::ComputationService,
        compute_and_upsert_record_for: nil
      )
      expect(StudentPerformance::ComputationService)
        .to receive(:new).with(lecture: lecture).and_return(service)
      expect(service).to receive(:compute_and_upsert_record_for).with(user)

      FactoryBot.create(:lecture_membership, lecture: lecture, user: user)
    end

    it "seeds existing achievement participations when a membership is created" do
      achievement = FactoryBot.create(:achievement, lecture: lecture)

      expect do
        FactoryBot.create(:lecture_membership, lecture: lecture, user: user)
      end.to change {
        achievement.assessment.assessment_participations.where(user: user).count
      }.from(0).to(1)
    end

    it "removes the performance record when a membership is destroyed" do
      membership = FactoryBot.create(:lecture_membership,
                                     lecture: lecture, user: user)
      expect(StudentPerformance::Record.where(lecture: lecture, user: user))
        .to exist

      membership.destroy!

      expect(StudentPerformance::Record.where(lecture: lecture, user: user))
        .not_to exist
    end

    # An admission whose performance data is gone is one nobody could account
    # for later, and it would still admit: the screening reads the row alone.
    it "removes the exam admission as well, decided by hand or not" do
      membership = FactoryBot.create(:lecture_membership,
                                     lecture: lecture, user: user)
      FactoryBot.create(:student_performance_certification, :passed, :manual,
                        lecture: lecture, user: user)

      membership.destroy!

      expect(StudentPerformance::Certification.where(lecture: lecture,
                                                     user: user))
        .not_to exist
    end

    it "removes the performance data on exclusion and rebuilds the record on return" do
      membership = FactoryBot.create(:lecture_membership, lecture: lecture, user: user)
      FactoryBot.create(:student_performance_certification, :passed,
                        lecture: lecture, user: user)

      membership.exclude!(by: user)

      expect(StudentPerformance::Record.where(lecture: lecture, user: user)).not_to exist
      expect(StudentPerformance::Certification.where(lecture: lecture, user: user))
        .not_to exist

      lecture.add_user_to_roster!(user)

      expect(StudentPerformance::Record.where(lecture: lecture, user: user)).to exist
      expect(StudentPerformance::Certification.where(lecture: lecture, user: user))
        .not_to exist
    end
  end

  describe "exclusion" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:user) { FactoryBot.create(:confirmed_user) }
    let(:staff) { FactoryBot.create(:confirmed_user) }

    it "keeps the row but takes the user off the roster, noting who did it" do
      membership = FactoryBot.create(:lecture_membership, lecture: lecture, user: user)

      lecture.remove_user_from_roster!(user, by: staff)

      expect(lecture.members).not_to include(user)
      expect(lecture.excluded_lecture_memberships).to contain_exactly(membership)
      expect(membership.reload.excluded_by).to eq(staff)
      expect(membership.left_by_self?).to be(false)
    end

    # A reader that forgot the active scope would still count them.
    it "counts the user as a member nowhere once excluded" do
      restricted = FactoryBot.create(:lecture, :released_for_all, passphrase: "secret")
      FactoryBot.create(:lecture_membership, lecture: restricted, user: user).exclude!(by: user)
      board = Dashboard::Board.new(user: user, term: restricted.term)

      expect(restricted.members).not_to include(user)
      expect(user.enrolled_lectures).not_to include(restricted)
      expect(user.roster_lectures).not_to include(restricted)
      expect(restricted.registration_mail_recipients).not_to include(user)
      expect(LectureAudience.users([restricted.id])).not_to include(user)
      expect(LectureAudience.lectures_of(user)).not_to include(restricted)
      expect(board.enrolled_lectures).not_to include(restricted)
      expect(restricted.bookmarkable_by?(user)).to be(false)
      expect(Rosters::LectureLeave.new(restricted, user).participating?).to be(false)
      expect(Rosters::UserPlaces.new(user).any?).to be(false)
    end

    it "takes the same row back when the user is added again" do
      membership = FactoryBot.create(:lecture_membership, lecture: lecture, user: user)
      membership.exclude!(by: user)

      joined_at = membership.created_at
      lecture.add_user_to_roster!(user)

      expect(lecture.members).to include(user)
      expect(membership.reload.excluded_at).to be_nil
      expect(membership.created_at).to eq(joined_at)
      expect(LectureMembership.where(lecture: lecture, user: user).count).to eq(1)
    end
  end
end
