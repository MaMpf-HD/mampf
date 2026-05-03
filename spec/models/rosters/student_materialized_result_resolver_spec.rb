require "rails_helper"

RSpec.describe(Rosters::StudentMaterializedResultResolver, type: :service) do
  let(:user) { create(:user) }

  describe "get succeeded registration in tutorial campaign" do
    let(:campaign) { create(:registration_campaign, :with_items, :preference_based) }
    let(:tutorial) { campaign.registration_items.first.registerable }
    subject { described_class.new(user) }

    context "when user is already in roster" do
      before do
        create(:tutorial_membership,
               tutorial: tutorial,
               user: user,
               source_campaign_id: campaign.id)
      end
      it "should return a succeeded item" do
        result = subject.succeed_items(campaign)
        expect(result.count).to eq(1)
      end
    end

    context "when user not in roster" do
      it "should return 0 succeeded item" do
        result = subject.succeed_items(campaign)
        expect(result.count).to eq(0)
      end
    end
  end

  describe "get succeeded registration in talk campaign" do
    let(:campaign) { create(:registration_campaign, :for_seminar, :with_items, :preference_based) }
    let(:talk) { campaign.registration_items.first.registerable }
    subject { described_class.new(user) }

    context "when user is already in roster" do
      before do
        create(:speaker_talk_join,
               talk: talk,
               speaker: user,
               source_campaign_id: campaign.id)
      end
      it "should return a succeeded item" do
        result = subject.succeed_items(campaign)
        expect(result.count).to eq(1)
      end
    end

    context "when user not in roster" do
      it "should return 0 succeeded item" do
        result = subject.succeed_items(campaign)
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
    subject { described_class.new(user) }

    context "when user is already in roster" do
      before do
        create(:cohort_membership,
               cohort: cohort,
               user: user,
               source_campaign_id: campaign.id)
      end
      it "should return a succeeded item" do
        result = subject.succeed_items(campaign)
        expect(result.count).to eq(1)
      end
    end

    context "when user not in roster" do
      it "should return 0 succeeded item" do
        result = subject.succeed_items(campaign)
        expect(result.count).to eq(0)
      end
    end
  end

  describe "#all_rosterized_for_lecture" do
    let(:lecture) { create(:lecture) }
    let!(:tutorial) do
      create(:tutorial, :with_tutors, lecture: lecture, title: "Tutorial 2")
    end
    let!(:cohort) do
      create(:cohort, context: lecture, title: "Repeaters", description: "Extra support")
    end

    before do
      create(:tutorial_membership, tutorial: tutorial, user: user)
      create(:cohort_membership, cohort: cohort, user: user)
    end

    it "returns rosterables for the lecture with their associations preloaded" do
      result = described_class.new(user).all_rosterized_for_lecture(lecture)

      expect(result).to match_array([tutorial, cohort])
      expect(result.find { |entry| entry == tutorial }.association(:tutors)).to be_loaded
      expect(result.find { |entry| entry == tutorial }.association(:members)).to be_loaded
      expect(result.find { |entry| entry == cohort }.association(:members)).to be_loaded
    end

    it "returns nil when the user has no rosterized entries for the lecture" do
      other_user = create(:user)

      result = described_class.new(other_user).all_rosterized_for_lecture(lecture)

      expect(result).to be_nil
    end
  end
end
