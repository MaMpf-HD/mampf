require "rails_helper"

RSpec.describe(Rosters::SelfRosterAvailability) do
  describe "#blocked_by_unremovable_assignment?" do
    let(:lecture) { instance_double(Lecture) }
    let(:user) { instance_double(User) }

    def availability_with(rosterable)
      availability = described_class.new(lecture, user)
      allow(availability).to receive(:rosterized_entries).and_return([rosterable])
      availability
    end

    it "blocks on an allocated, non-removable entry in a roster-exclusive " \
       "pool" do
      rosterable = instance_double(
        "Rosterable",
        roster_exclusive_within_lecture?: true,
        user_allocated?: true,
        config_allow_self_remove?: false
      )

      expect(availability_with(rosterable).blocked_by_unremovable_assignment?)
        .to be(true)
    end

    it "does not block when the allocated entry can be self-removed" do
      rosterable = instance_double(
        "Rosterable",
        roster_exclusive_within_lecture?: true,
        user_allocated?: true,
        config_allow_self_remove?: false
      )
      allow(rosterable).to receive(:config_allow_self_remove?).and_return(true)

      expect(availability_with(rosterable).blocked_by_unremovable_assignment?)
        .to be(false)
    end

    it "does not block on a non-exclusive pool (e.g. an interest cohort or " \
       "talk), even if unremovable" do
      # regression: a confirmed, unremovable membership in a non-exclusive
      # pool (a cohort/talk) must not block registration in another campaign
      rosterable = instance_double(
        "Rosterable",
        roster_exclusive_within_lecture?: false,
        user_allocated?: true,
        config_allow_self_remove?: false
      )

      expect(availability_with(rosterable).blocked_by_unremovable_assignment?)
        .to be(false)
    end
  end
end
