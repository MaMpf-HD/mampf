require "rails_helper"

RSpec.describe(Registration::UserRegistration::PreferencesHandler, type: :service) do
  let(:user) { FactoryBot.create(:user, email: "student@mampf.edu") }
  let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }

  describe "edit preference tutorial campaign" do
    let(:campaign) { FactoryBot.create(:registration_campaign, :preference_based, :open) }
    let(:campaign_draft) do
      FactoryBot.create(:registration_campaign, :preference_based, :draft, :with_items)
    end
    let(:item) { campaign.registration_items.first }
    let(:item2) { campaign.registration_items.second }
    let(:item3) { campaign.registration_items.third }
    let(:pref_from_fe) { Registration::UserRegistration::PreferencesHandler::ItemPreference.new(item2, 1) }
    let(:pref_from_fe2) { Registration::UserRegistration::PreferencesHandler::ItemPreference.new(item, 2) }
    let(:pref_from_fe3) { Registration::UserRegistration::PreferencesHandler::ItemPreference.new(item3, 3) }
    let(:pref_items_json) { [pref_from_fe, pref_from_fe2, pref_from_fe3].to_json }
    let(:pref_items_json2) { [pref_from_fe, pref_from_fe2].to_json }

    it "result before saved must be normalized" do
      service = described_class.new
      pref_from_fe2_incorrect = Registration::UserRegistration::PreferencesHandler::SimpleItemPreference.new(
        item.id, 3
      )
      pref_items_json_incorrect = [pref_from_fe, pref_from_fe2_incorrect].to_json
      result = service.pref_item_build_for_save(pref_items_json_incorrect)
      expect(result.size).to eq(2)
      expect(result.first.rank).to eq(1)
      expect(result.last.rank).to eq(2)
    end

    it "up should swap rank selected item and item before it" do
      result = described_class.new.up(item3.id, pref_items_json)
      expect(result.first.item.id).to equal(item2.id)
      expect(result.first.rank).to equal(1)
      expect(result.second.item.id).to equal(item3.id)
      expect(result.second.rank).to equal(2)
      expect(result.third.item.id).to equal(item.id)
      expect(result.third.rank).to equal(3)
    end

    it "down should swap rank selected item and item below it" do
      result = described_class.new.down(item2.id, pref_items_json)
      expect(result.first.item.id).to equal(item.id)
      expect(result.first.rank).to equal(1)
      expect(result.second.item.id).to equal(item2.id)
      expect(result.second.rank).to equal(2)
      expect(result.third.item.id).to equal(item3.id)
      expect(result.third.rank).to equal(3)
    end

    it "add should add item selected into result" do
      result = described_class.new.add(item3.id, pref_items_json2)
      expect(result.size).to equal(3)
    end

    it "no duplicating adding" do
      result = described_class.new.add(item2.id, pref_items_json2)
      expect(result.size).to equal(2)
    end

    it "remove should remove item selected out of result" do
      result = described_class.new.remove(item3.id, pref_items_json)
      expect(result.count).to equal(2)
    end
  end
end
