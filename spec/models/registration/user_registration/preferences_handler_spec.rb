require "rails_helper"

RSpec.describe(Registration::UserRegistration::PreferencesHandler, type: :service) do
  let(:user) { FactoryBot.create(:user, email: "student@mampf.edu") }
  let(:lecture) { FactoryBot.create(:lecture) }

  describe "edit preference tutorial campaign" do
    let(:campaign) { FactoryBot.create(:registration_campaign, :preference_based, :open) }
    let(:item) { campaign.registration_items.first }
    let(:item2) { campaign.registration_items.second }
    let(:item3) { campaign.registration_items.third }

    it "build with rank should preserve the selected rank" do
      result = described_class.new.pref_item_build_with_rank(campaign, user,
                                                             item.id, 3)
      expect(result.first.id).to eq(item.id)
      expect(result.first.rank).to eq(3)
    end

    it "build with rank should keep ranks unique" do
      Registration::UserRegistration.create!(
        registration_campaign: campaign,
        registration_item: item2,
        user: user,
        status: :pending,
        preference_rank: 1
      )

      result = described_class.new.pref_item_build_with_rank(campaign, user,
                                                             item.id, 1)
      expect(result.map(&:rank)).to contain_exactly(1, 2)
    end

    it "build with rank should replace an option at the preference limit" do
      extra_item = create(:registration_item, registration_campaign: campaign)
      [item2, item, item3].each_with_index do |registration_item, index|
        Registration::UserRegistration.create!(
          registration_campaign: campaign,
          registration_item: registration_item,
          user: user,
          status: :pending,
          preference_rank: index + 1
        )
      end

      result = described_class.new.pref_item_build_with_rank(campaign, user,
                                                             extra_item.id, 2)
      expect(result.size).to eq(3)
      expect(result.map(&:rank)).to contain_exactly(1, 2, 3)
      expect(result.find { |pref| pref.id == extra_item.id }.rank).to eq(2)
    end
  end
end
