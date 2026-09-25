require "rails_helper"

RSpec.describe(LectureHomeHelper, type: :helper) do
  let(:campaign) { double(campaign: double) }
  let(:exam) { double }

  before do
    helper.extend(UserRegistrationsHelper)
  end

  describe "#lecture_home_focus" do
    it "leads with a campaign the student still has to register in" do
      allow(helper).to receive(:registration_needs_action?).and_return(true)

      expect(helper.lecture_home_focus(campaigns: [campaign], next_exam: exam).kind)
        .to eq(:campaign)
    end

    it "leads with the next exam when no campaign waits" do
      allow(helper).to receive(:registration_needs_action?).and_return(false)

      expect(helper.lecture_home_focus(campaigns: [campaign], next_exam: exam).kind)
        .to eq(:exam)
    end

    it "leads with nothing when nothing is due" do
      expect(helper.lecture_home_focus(campaigns: [], next_exam: nil)).to be_nil
    end
  end
end
