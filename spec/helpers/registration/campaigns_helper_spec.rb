require "rails_helper"

RSpec.describe(Registration::CampaignsHelper, type: :helper) do
  describe "#campaign_badge_color" do
    it "returns the correct color for each status" do
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :draft)))
        .to eq("secondary")
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :open)))
        .to eq("success")
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :closed)))
        .to eq("warning")
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :processing)))
        .to eq("info")
      expect(helper.campaign_badge_color(build(:registration_campaign, status: :completed)))
        .to eq("dark")
    end
  end

  describe "#sorted_preference_counts" do
    it "sorts ranks correctly with forced last" do
      stats = double(preference_counts: { 2 => 10, :forced => 5, 1 => 20 })
      sorted = helper.sorted_preference_counts(stats)
      expect(sorted).to eq([[1, 20], [2, 10], [:forced, 5]])
    end
  end

  describe "#rank_color" do
    it "returns correct colors for ranks" do
      expect(helper.rank_color(1)).to eq(:success)
      expect(helper.rank_color(2)).to eq(:primary)
      expect(helper.rank_color(3)).to eq(:secondary)
      expect(helper.rank_color(:forced)).to eq(:danger)
    end
  end

  describe "#campaign_close_confirmation" do
    it "returns the correct confirmation message" do
      campaign = build(:registration_campaign, registration_deadline: 1.day.from_now)
      expect(helper.campaign_close_confirmation(campaign))
        .to eq(I18n.t("registration.campaign.confirmations.close_early"))

      campaign.registration_deadline = 1.day.ago
      expect(helper.campaign_close_confirmation(campaign))
        .to eq(I18n.t("registration.campaign.confirmations.close"))
    end
  end

  describe "#no_campaign_registerables" do
    let(:lecture) { create(:lecture) }

    it "includes cohorts regardless of skip_campaigns" do
      cohort_included = create(:cohort, context: lecture, title: "A cohort")
      cohort_excluded_before = create(:cohort,
                                      context: lecture,
                                      title: "B cohort",
                                      skip_campaigns: false)

      result = helper.no_campaign_registerables(lecture)

      expect(result).to include(cohort_included)
      expect(result).to include(cohort_excluded_before)
    end

    it "keeps tutorials filtered by skip_campaigns" do
      tutorial_visible = create(:tutorial,
                                lecture: lecture,
                                title: "A tutorial",
                                skip_campaigns: true)
      tutorial_in_campaign = create(:tutorial,
                                    lecture: lecture,
                                    title: "B tutorial",
                                    skip_campaigns: false)
      campaign = create(:registration_campaign,
                        :open,
                        campaignable: lecture)
      create(:registration_item,
             registration_campaign: campaign,
             registerable: tutorial_in_campaign)

      result = helper.no_campaign_registerables(lecture)

      expect(result).to include(tutorial_visible)
      expect(result).not_to include(tutorial_in_campaign)
      expect(result.count { |entry| entry.is_a?(Tutorial) }).to eq(1)
    end

    it "includes tutorials from completed campaigns" do
      tutorial = create(:tutorial,
                        lecture: lecture,
                        title: "C tutorial",
                        skip_campaigns: false)
      campaign = create(:registration_campaign,
                        :completed,
                        campaignable: lecture)
      create(:registration_item,
             registration_campaign: campaign,
             registerable: tutorial)

      result = helper.no_campaign_registerables(lecture)

      expect(result).to include(tutorial)
    end
  end

  describe "#rank_label" do
    it "returns forced label for :forced" do
      expect(helper.rank_label(:forced)).to eq(I18n.t("registration.allocation.stats.forced"))
    end

    it "returns rank label for numbers" do
      expect(helper.rank_label(1)).to eq(I18n.t("registration.allocation.stats.rank_label",
                                                rank: 1))
    end
  end

  describe "button helpers with params" do
    let(:campaign) do
      create(:registration_campaign, :open,
             registration_deadline: 1.week.from_now)
    end
    let(:frame_params) { { frame_id: "exam_1_registration" } }

    describe "#open_campaign_button" do
      it "renders a button_to with params embedded in hidden fields" do
        html = helper.open_campaign_button(campaign, params: frame_params)
        expect(html).to include('name="frame_id"')
        expect(html).to include('value="exam_1_registration"')
      end
    end

    describe "#close_campaign_button" do
      it "renders a button_to with params embedded in hidden fields" do
        html = helper.close_campaign_button(campaign, params: frame_params)
        expect(html).to include('name="frame_id"')
        expect(html).to include('value="exam_1_registration"')
      end
    end

    describe "#reopen_campaign_button" do
      it "renders a button_to with params embedded in hidden fields" do
        html = helper.reopen_campaign_button(campaign, params: frame_params)
        expect(html).to include('name="frame_id"')
        expect(html).to include('value="exam_1_registration"')
      end
    end

    describe "#finalize_campaign_button" do
      it "renders a button_to with params embedded in hidden fields" do
        html = helper.finalize_campaign_button(campaign, params: frame_params)
        expect(html).to include('name="frame_id"')
        expect(html).to include('value="exam_1_registration"')
      end
    end

    describe "#allocate_campaign_button" do
      it "renders a button_to with params embedded in hidden fields" do
        html = helper.allocate_campaign_button(campaign, params: frame_params)
        expect(html).to include('name="frame_id"')
        expect(html).to include('value="exam_1_registration"')
      end
    end

    describe "#view_allocation_button" do
      it "includes params in the URL" do
        html = helper.view_allocation_button(campaign, params: frame_params)
        expect(html).to include("frame_id=exam_1_registration")
      end
    end

    describe "#review_and_finalize_button" do
      it "includes params in the URL" do
        html = helper.review_and_finalize_button(campaign,
                                                 params: frame_params)
        expect(html).to include("frame_id=exam_1_registration")
      end
    end
  end
end
