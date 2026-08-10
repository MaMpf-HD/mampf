require "rails_helper"

RSpec.describe(SubmissionsHelper, type: :helper) do
  let(:user) { create(:confirmed_user) }
  let(:lecture)          { create(:lecture) }
  let(:other_lecture)    { create(:lecture) }
  let(:tutorial)         { create(:tutorial, lecture: lecture) }
  let(:other_tutorial)   { create(:tutorial, lecture: other_lecture) }

  before do
    allow(helper).to receive(:current_user).and_return(user)

    Flipper.enable(:roster_maintenance)
    Flipper.enable(:registration_campaigns)
  end

  after do
    Flipper.disable(:roster_maintenance)
    Flipper.disable(:registration_campaigns)
  end

  describe "#enabled_roster_for_lecture?" do
    before { create(:tutorial_membership, tutorial: tutorial) } # makes lecture roster-eligible

    it "only queries roster_eligible_tutorials? once per lecture (memoized)" do
      expect(lecture).to receive(:roster_eligible_tutorials?).once.and_call_original

      first  = helper.enabled_roster_for_lecture?(lecture)
      second = helper.enabled_roster_for_lecture?(lecture)

      expect(first).to eq(true)
      expect(second).to eq(true)
    end

    it "computes independently per lecture (no cross-lecture leakage)" do
      # other_lecture has no roster-eligible tutorials
      expect(helper.enabled_roster_for_lecture?(lecture)).to eq(true)
      expect(helper.enabled_roster_for_lecture?(other_lecture)).to eq(false)
    end
  end

  describe "#rostered_tutorial_for" do
    before { create(:tutorial_membership, tutorial: tutorial, user: user) }

    it "only queries rostered_tutorial_in once per lecture (memoized)" do
      expect(user).to receive(:rostered_tutorial_in).once.with(lecture).and_return(tutorial)

      first  = helper.rostered_tutorial_for(lecture)
      second = helper.rostered_tutorial_for(lecture)

      expect(first).to eq(tutorial)
      expect(second).to eq(tutorial)
    end

    it "computes independently per lecture (no cross-lecture leakage)" do
      create(:tutorial_membership, tutorial: other_tutorial, user: user)

      expect(helper.rostered_tutorial_for(lecture)).to eq(tutorial)
      expect(helper.rostered_tutorial_for(other_lecture)).to eq(other_tutorial)
    end

    it "returns nil without querying rostered_tutorial_in when lecture is not roster-eligible" do
      not_eligible_lecture = create(:lecture)
      expect(user).not_to receive(:rostered_tutorial_in)

      expect(helper.rostered_tutorial_for(not_eligible_lecture)).to be_nil
    end
  end

  describe "#roster_cache" do
    it "returns the same hash across multiple calls within one helper instance" do
      first  = helper.roster_cache
      second = helper.roster_cache

      expect(first).to equal(second) # same object, not just equal value
    end
  end
end
