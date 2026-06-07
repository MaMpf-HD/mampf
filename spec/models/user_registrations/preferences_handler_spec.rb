require "rails_helper"

RSpec.describe(UserRegistrations::PreferencesHandler, type: :service) do
  let(:user) { FactoryBot.create(:user, email: "student@mampf.edu") }
  let(:lecture) { FactoryBot.create(:lecture) }

  describe "edit preference tutorial campaign" do
    let(:campaign) { FactoryBot.create(:registration_campaign, :preference_based, :open) }
    let(:item) { campaign.registration_items.first }
    let(:item2) { campaign.registration_items.second }
    let(:item3) { campaign.registration_items.third }

    it "builds simple preference items from ranked params" do
      result = described_class.new.pref_items_from_ranked_params(
        "3" => item3.id,
        "1" => item.id,
        "2" => item2.id
      )

      expect(result.map(&:id)).to eq([item.id, item2.id, item3.id])
      expect(result.map(&:rank)).to eq([1, 2, 3])
    end

    it "ignores blank choices" do
      result = described_class.new.pref_items_from_ranked_params(
        "1" => item.id,
        "2" => "",
        "3" => item3.id
      )

      expect(result.map(&:rank)).to eq([1, 3])
    end

    it "returns persisted preferences ordered by rank" do
      [item2, item, item3].each_with_index do |registration_item, index|
        Registration::UserRegistration.create!(
          registration_campaign: campaign,
          registration_item: registration_item,
          user: user,
          status: :pending,
          preference_rank: index + 1
        )
      end

      result = described_class.new.preferences_info(campaign, user)

      expect(result.map(&:item)).to eq([item2, item, item3])
      expect(result.map(&:rank)).to eq([1, 2, 3])
    end
  end
end
