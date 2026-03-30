require "rails_helper"

RSpec.describe(Rosters::StudentMainResultResolver, type: :service) do
  let(:user) { create(:user) }

  describe "get succeeded registration in tutorial campaign" do
    let(:campaign) { create(:registration_campaign, :with_items, :preference_based) }
    let(:tutorial) { campaign.registration_items.first.registerable }
    subject { described_class.new(campaign, user) }

    context "when user is already in roster" do
      before do
        create(:tutorial_membership,
               tutorial: tutorial,
               user: user,
               source_campaign_id: campaign.id)
      end
      it "should return a succeeded item" do
        result = subject.succeed_items
        expect(result.count).to eq(1)
      end
    end

    context "when user not in roster" do
      it "should return 0 succeeded item" do
        result = subject.succeed_items
        expect(result.count).to eq(0)
      end
    end
  end

  describe "get succeeded registration in talk campaign" do
    let(:campaign) { create(:registration_campaign, :for_seminar, :with_items, :preference_based) }
    let(:talk) { campaign.registration_items.first.registerable }
    subject { described_class.new(campaign, user) }

    context "when user is already in roster" do
      before do
        create(:speaker_talk_join,
               talk: talk,
               speaker: user,
               source_campaign_id: campaign.id)
      end
      it "should return a succeeded item" do
        result = subject.succeed_items
        expect(result.count).to eq(1)
      end
    end

    context "when user not in roster" do
      it "should return 0 succeeded item" do
        result = subject.succeed_items
        expect(result.count).to eq(0)
      end
    end
  end

  describe "get succeeded registration in cohort campaign" do
    let(:campaign) do
      create(:registration_campaign, :for_seminar, :with_items, :preference_based,
             { for_cohorts: true })
    end
    let(:cohort) { campaign.registration_items.first.registerable }
    subject { described_class.new(campaign, user) }

    context "when user is already in roster" do
      before do
        create(:cohort_membership,
               cohort: cohort,
               user: user,
               source_campaign_id: campaign.id)
      end
      it "should return a succeeded item" do
        result = subject.succeed_items
        expect(result.count).to eq(1)
      end
    end

    context "when user not in roster" do
      it "should return 0 succeeded item" do
        result = subject.succeed_items
        expect(result.count).to eq(0)
      end
    end
  end
end
