require "rails_helper"

RSpec.describe(Registration::Item, type: :model) do
  describe "factory" do
    it "creates a valid default item with tutorial" do
      item = FactoryBot.create(:registration_item)
      expect(item).to be_valid
      expect(item.registerable_type).to eq("Tutorial")
      expect(item.registerable.lecture).to eq(item.registration_campaign.campaignable)
    end

    it "creates a valid item for tutorial" do
      item = FactoryBot.create(:registration_item, :for_tutorial)
      expect(item).to be_valid
      expect(item.registerable_type).to eq("Tutorial")
      expect(item.registerable.lecture).to eq(item.registration_campaign.campaignable)
    end

    it "creates a valid item for talk" do
      item = FactoryBot.create(:registration_item, :for_talk)
      expect(item).to be_valid
      expect(item.registerable_type).to eq("Talk")
      expect(item.registerable.lecture).to eq(item.registration_campaign.campaignable)
    end

    it "creates a valid item for lecture" do
      item = FactoryBot.create(:registration_item, :for_lecture)
      expect(item).to be_valid
      expect(item.registerable_type).to eq("Lecture")
      expect(item.registerable).to eq(item.registration_campaign.campaignable)
    end
  end
end
