require "rails_helper"

RSpec.describe(Exam, type: :model) do
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
