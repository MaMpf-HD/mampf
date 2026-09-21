require "rails_helper"

RSpec.describe(AssignmentSighting, type: :model) do
  let(:user) { create(:confirmed_user) }
  let(:assignment) { create(:valid_assignment) }

  it "keeps one row per person and sheet" do
    described_class.stamp!(user: user, assignment: assignment)
    second = described_class.new(user: user, assignment: assignment)

    expect(second).not_to be_valid
  end

  describe ".stamp!" do
    it "writes the time of the first look" do
      at = 1.minute.ago

      described_class.stamp!(user: user, assignment: assignment, at: at)

      expect(described_class.find_by!(user: user, assignment: assignment).seen_at)
        .to be_within(1.second).of(at)
    end

    it "moves the time of an existing row rather than adding one" do
      described_class.stamp!(user: user, assignment: assignment, at: 1.day.ago)

      expect do
        described_class.stamp!(user: user, assignment: assignment)
      end.not_to change(described_class, :count)
      expect(described_class.find_by!(user: user, assignment: assignment).seen_at)
        .to be_within(5.seconds).of(Time.current)
    end
  end
end
