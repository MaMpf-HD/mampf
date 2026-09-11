require "rails_helper"

RSpec.describe(SubmissionsHelper, type: :helper) do
  let(:user) { create(:confirmed_user) }
  let(:lecture)          { create(:lecture) }
  let(:other_lecture)    { create(:lecture) }
  let(:tutorial)         { create(:tutorial, lecture: lecture) }
  let(:other_tutorial)   { create(:tutorial, lecture: other_lecture) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe "#enabled_roster_for_lecture?" do
    before { create(:tutorial_membership, tutorial: tutorial) } # makes lecture roster-eligible

    it "only queries roster_managed? once per lecture (memoized)" do
      expect(lecture).to receive(:roster_managed?).once.and_call_original

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

    # The question is the seat, not what kind of lecture it is: a hand-in goes
    # to the group the reader sits in, and somebody who sits in none has no
    # group here either.
    it "returns nil for a lecture the reader sits in no group of" do
      expect(helper.rostered_tutorial_for(create(:lecture))).to be_nil
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
