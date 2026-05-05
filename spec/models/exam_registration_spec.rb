require "rails_helper"

RSpec.describe(Exam, type: :model) do
  describe "validations" do
    describe "registration_deadline" do
      it "is invalid when deadline is in the past on create" do
        exam = build(:exam, :with_date, registration_deadline: 1.day.ago)

        expect(exam).to be_invalid
        expect(exam.errors.where(:registration_deadline, :must_be_in_future))
          .to be_present
      end

      it "is valid when deadline is in the future on create" do
        exam = build(:exam, :with_date,
                     registration_deadline: 3.days.from_now)

        expect(exam).to be_valid
      end

      it "is invalid when deadline is after the exam date" do
        exam = build(:exam, date: 1.week.from_now,
                            registration_deadline: 2.weeks.from_now)

        expect(exam).to be_invalid
        expect(exam.errors.where(:registration_deadline, :must_be_before_exam_date))
          .to be_present
      end
    end
  end

  describe "roster methods" do
    let(:exam) { create(:exam) }
    let(:user) { create(:confirmed_user) }

    it "adds users to the active roster" do
      expect do
        exam.add_user_to_roster!(user)
      end.to change(ExamRosterEntry, :count).by(1)

      expect(exam.reload.exam_roster_entries.map(&:user_id)).to include(user.id)
    end

    it "reactivates previously excluded users" do
      roster_entry = create(:exam_roster_entry,
                            exam: exam,
                            user: user,
                            excluded_at: Time.current)

      expect do
        exam.add_user_to_roster!(user)
      end.not_to change(ExamRosterEntry, :count)

      expect(roster_entry.reload.excluded_at).to be_nil
    end

    it "removes users from the roster" do
      create(:exam_roster_entry, exam: exam, user: user)

      expect do
        exam.remove_user_from_roster!(user)
      end.to change(ExamRosterEntry, :count).by(-1)
    end

    it "is not destructible while active participants exist" do
      create(:exam_roster_entry, exam: exam, user: user)

      expect(exam.reload.non_destructible_reason).to eq(:roster_not_empty)
      expect(exam).not_to be_destructible
    end
  end
end
