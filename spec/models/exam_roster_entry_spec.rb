require "rails_helper"

RSpec.describe(ExamRosterEntry, type: :model) do
  it "has a valid factory" do
    expect(build(:exam_roster_entry)).to be_valid
  end

  describe "validations" do
    it "is invalid without an exam" do
      expect(build(:exam_roster_entry, exam: nil)).to be_invalid
    end

    it "is invalid without a user" do
      expect(build(:exam_roster_entry, user: nil)).to be_invalid
    end

    it "is invalid with duplicate user for same exam" do
      roster_entry = create(:exam_roster_entry)
      duplicate = build(:exam_roster_entry,
                        exam: roster_entry.exam,
                        user: roster_entry.user)

      expect(duplicate).to be_invalid
    end
  end

  describe "associations" do
    it "allows nil source_campaign for manual additions" do
      roster_entry = create(:exam_roster_entry, source_campaign: nil)

      expect(roster_entry.source_campaign).to be_nil
    end
  end

  describe "exclusion state" do
    it "returns the default exclusion reason label" do
      roster_entry = create(:exam_roster_entry, excluded_at: Time.current)

      expect(roster_entry.exclusion_reason_label).to eq(
        I18n.t("assessment.registration_tab.removed_from_roster_reason")
      )
    end

    it "scopes active and excluded rows separately" do
      active_roster_entry = create(:exam_roster_entry)
      excluded_roster_entry = create(:exam_roster_entry,
                                     excluded_at: Time.current)

      expect(described_class.active).to include(active_roster_entry)
      expect(described_class.active).not_to include(excluded_roster_entry)
      expect(described_class.excluded).to include(excluded_roster_entry)
      expect(described_class.excluded).not_to include(active_roster_entry)
    end
  end
end
