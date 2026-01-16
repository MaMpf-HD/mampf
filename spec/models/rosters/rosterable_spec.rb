require "rails_helper"

RSpec.describe(Rosters::Rosterable) do
  describe "#materialize_allocation!" do
    let(:rosterable) { create(:tutorial) }
    let(:campaign) { create(:registration_campaign) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    before do
      # Initial state: user1 is in roster (via campaign), user2 is in roster (manual)
      rosterable.add_user_to_roster!(user1, campaign)
      rosterable.add_user_to_roster!(user2, nil)
    end

    it "adds new users from the list" do
      rosterable.materialize_allocation!(user_ids: [user1.id, user3.id], campaign: campaign)
      expect(rosterable.allocated_user_ids).to include(user3.id)
    end

    it "removes users not in the list who were added by this campaign" do
      rosterable.materialize_allocation!(user_ids: [user3.id], campaign: campaign)
      expect(rosterable.allocated_user_ids).not_to include(user1.id)
    end

    it "preserves manual entries" do
      rosterable.materialize_allocation!(user_ids: [user1.id], campaign: campaign)
      expect(rosterable.allocated_user_ids).to include(user2.id)
    end

    it "preserves entries from other campaigns" do
      other_campaign = create(:registration_campaign)
      rosterable.add_user_to_roster!(user3, other_campaign)

      rosterable.materialize_allocation!(user_ids: [user1.id], campaign: campaign)
      expect(rosterable.allocated_user_ids).to include(user3.id)
    end

    context "propagation to lecture roster" do
      let(:lecture) { rosterable.lecture }

      it "propagates tutorial allocations to the parent lecture" do
        rosterable.materialize_allocation!(user_ids: [user3.id], campaign: campaign)
        expect(lecture.allocated_user_ids).to include(user3.id)
      end

      context "with a cohort" do
        let(:rosterable) { create(:cohort, context: create(:lecture)) }
        let(:lecture) { rosterable.lecture }

        it "does not propagate by default" do
          rosterable.materialize_allocation!(user_ids: [user3.id], campaign: campaign)
          expect(lecture.allocated_user_ids).not_to include(user3.id)
        end

        it "propagates when propagate_to_lecture is enabled" do
          propagating = create(:cohort, context: lecture, propagate_to_lecture: true)
          expect(propagating.propagate_to_lecture?).to be(true)

          propagating.materialize_allocation!(user_ids: [user3.id], campaign: campaign)
          expect(lecture.allocated_user_ids).to include(user3.id)
        end
      end
    end
  end
end
