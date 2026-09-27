require "rails_helper"

RSpec.describe(Lectures::CampaignCounts) do
  let(:lecture) { create(:lecture) }
  let(:student) { create(:confirmed_user) }

  it "counts a person in two cohorts of a finalized campaign once" do
    campaign = create(:registration_campaign, :completed, campaignable: lecture,
                                                          for_cohorts: true, items_count: 2)
    campaign.registration_items.each do |item|
      create(:cohort_membership, cohort: item.registerable, user: student)
    end

    expect(described_class.new([campaign.reload]).to_h).to eq(campaign.id => 1)
  end

  it "counts the people on the tutorial rosters of a finalized campaign" do
    campaign = create(:registration_campaign, :completed, campaignable: lecture,
                                                          items_count: 2)
    first, second = campaign.registration_items.map(&:registerable)
    create(:tutorial_membership, tutorial: first, user: student)
    create(:tutorial_membership, tutorial: second, user: create(:confirmed_user))

    expect(described_class.new([campaign.reload]).to_h).to eq(campaign.id => 2)
  end

  it "counts the people registered while a campaign runs" do
    campaign = create(:registration_campaign, :open, :first_come_first_served,
                      campaignable: lecture)
    item = campaign.registration_items.first
    create(:registration_user_registration, :confirmed, registration_campaign: campaign,
                                                        registration_item: item, user: student)
    create(:registration_user_registration, :rejected, registration_campaign: campaign,
                                                       registration_item: item)

    expect(described_class.new([campaign]).to_h).to eq(campaign.id => 1)
  end
end
