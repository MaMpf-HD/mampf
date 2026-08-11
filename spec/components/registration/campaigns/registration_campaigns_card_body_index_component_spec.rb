require "rails_helper"

RSpec.describe(RegistrationCampaignsCardBodyIndexComponent, type: :component) do
  describe ".normalize_registration_section" do
    it "keeps supported registration sections" do
      expect(described_class.normalize_registration_section("campaign"))
        .to eq("campaign")
      expect(described_class.normalize_registration_section("no_campaign"))
        .to eq("no_campaign")
    end

    it "returns nil for unsupported registration sections" do
      expect(described_class.normalize_registration_section("other")).to be_nil
      expect(described_class.normalize_registration_section(nil)).to be_nil
    end
  end

  describe "#no_campaign_groups" do
    it "delegates to Rosters::NoCampaignRegisterablesQuery" do
      lecture = build_stubbed(:lecture)
      query = instance_double(Rosters::NoCampaignRegisterablesQuery)
      component = described_class.new(lecture: lecture)

      expect(Rosters::NoCampaignRegisterablesQuery)
        .to receive(:new).with(lecture).and_return(query)
      expect(query).to receive(:call).and_return([])

      expect(component.no_campaign_groups).to eq([])
    end
  end

  describe "collapse state" do
    it "keeps the no-campaign section open when only completed campaigns remain" do
      lecture = create(:lecture)
      create(:registration_campaign, :completed, campaignable: lecture)
      tutorial = create(:tutorial, lecture: lecture)

      component = described_class.new(lecture: lecture,
                                      registration_section: "campaign")

      allow(component).to receive(:no_campaign_groups).and_return([tutorial])

      expect(component.collapse_campaign_section?).to be(true)
      expect(component.collapse_no_campaign_section?).to be(false)
    end
  end
end
