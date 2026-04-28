require "rails_helper"

RSpec.describe(Registration::StatusEvent, type: :model) do
  describe "factory" do
    it "creates a valid default status event" do
      event = FactoryBot.create(:registration_status_event)

      expect(event).to be_valid
      expect(event.registration_campaign).to eq(event.registration.registration_campaign)
      expect(event.snapshot).to eq({ "label" => "Teacher rejected" })
    end
  end

  describe "validations" do
    it "requires the registration campaign to match the registration" do
      event = FactoryBot.build(:registration_status_event,
                               registration_campaign: FactoryBot.create(:registration_campaign))

      expect(event).not_to be_valid
      expect(event.errors[:registration_campaign]).to be_present
    end

    it "requires snapshot to be a hash" do
      event = FactoryBot.build(:registration_status_event, snapshot: ["invalid"])

      expect(event).not_to be_valid
      expect(event.errors[:snapshot]).to be_present
    end

    it "allows an empty snapshot hash" do
      event = FactoryBot.build(:registration_status_event, snapshot: {})

      expect(event).to be_valid
    end

    it "requires action to be from the known action set" do
      event = FactoryBot.build(:registration_status_event, action: "typo_reject")

      expect(event).not_to be_valid
      expect(event.errors[:action]).to be_present
    end
  end
end
