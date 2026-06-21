require "rails_helper"

RSpec.describe(CardBodyIndexComponent, type: :component) do
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
end
