require "rails_helper"

RSpec.describe(Rosters::SelfRosterAvailability) do
  describe "#blocked_by_unremovable_assignment?" do
    let(:lecture) { instance_double(Lecture) }
    let(:user) { instance_double(User) }

    it "treats an allocated non-removable entry as blocking even if self-add is disabled" do
      rosterable = instance_double(
        "Rosterable",
        user_allocated?: true,
        config_allow_self_add?: false,
        config_allow_self_remove?: false
      )
      availability = described_class.new(lecture, user)

      allow(availability).to receive(:rosterized_entries).and_return([rosterable])

      expect(availability.blocked_by_unremovable_assignment?).to be(true)
    end

    it "does not block when the allocated entry can be self-removed" do
      rosterable = instance_double(
        "Rosterable",
        user_allocated?: true,
        config_allow_self_add?: false,
        config_allow_self_remove?: true
      )
      availability = described_class.new(lecture, user)

      allow(availability).to receive(:rosterized_entries).and_return([rosterable])

      expect(availability.blocked_by_unremovable_assignment?).to be(false)
    end
  end
end
