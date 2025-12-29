require "rails_helper"

RSpec.describe(Rosters::Rosterable) do
  it "ensures all including models have a managed_by_campaign attribute" do
    # Eager load the application to ensure all models are loaded and discoverable
    Rails.application.eager_load!

    models = ApplicationRecord.descendants.select do |model|
      model.included_modules.include?(described_class)
    end

    models.each do |model|
      expect(model.new)
        .to(respond_to(:managed_by_campaign), "#{model} must have a managed_by_campaign attribute")
    end
  end

  describe "#locked?" do
    let(:rosterable) { create(:tutorial, managed_by_campaign: true) }

    context "when not managed_by_campaign" do
      before { rosterable.update(managed_by_campaign: false) }

      it "returns false" do
        expect(rosterable.locked?).to(be(false))
      end
    end

    context "when managed_by_campaign" do
      context "with no campaigns" do
        it "returns true" do
          expect(rosterable.locked?).to(be(true))
        end
      end

      context "with an open campaign" do
        before do
          campaign = create(:registration_campaign, status: :draft, planning_only: false)
          create(:registration_item, registration_campaign: campaign, registerable: rosterable)
          campaign.update(status: :open)
        end

        it "returns true" do
          expect(rosterable.locked?).to(be(true))
        end
      end

      context "with a completed planning campaign" do
        let(:rosterable) { create(:lecture) }

        before do
          campaign = create(:registration_campaign, status: :completed, planning_only: true,
                                                    campaignable: rosterable)
          create(:registration_item, registration_campaign: campaign, registerable: rosterable)
        end

        it "returns true" do
          expect(rosterable.locked?).to(be(true))
        end
      end

      context "with a completed non-planning campaign" do
        before do
          campaign = create(:registration_campaign, status: :completed, planning_only: false)
          create(:registration_item, registration_campaign: campaign, registerable: rosterable)
        end

        it "returns false" do
          expect(rosterable.locked?).to(be(false))
        end
      end
    end
  end

  describe "#can_disable_campaign_management?" do
    let(:rosterable) { create(:tutorial, managed_by_campaign: true) }

    context "when campaign is running" do
      before do
        campaign = create(:registration_campaign, campaignable: rosterable.lecture, status: :open,
                                                  planning_only: false)
        create(:registration_item, registration_campaign: campaign, registerable: rosterable)
      end

      it "returns false" do
        expect(rosterable.can_disable_campaign_management?).to(be(false))
      end
    end

    context "when no campaign is running" do
      it "returns true" do
        expect(rosterable.can_disable_campaign_management?).to(be(true))
      end
    end
  end

  describe "validations" do
    let(:rosterable) { create(:tutorial, managed_by_campaign: false) }

    context "when enabling managed_by_campaign" do
      context "when roster is empty" do
        it "is valid" do
          rosterable.managed_by_campaign = true
          expect(rosterable).to(be_valid)
        end
      end

      context "when roster is not empty" do
        before do
          rosterable.add_user_to_roster!(create(:user))
        end

        it "is invalid" do
          rosterable.managed_by_campaign = true
          expect(rosterable).not_to(be_valid)
          expect(rosterable.errors[:managed_by_campaign])
            .to(include(I18n.t("roster.errors.roster_not_empty")))
        end
      end
    end

    context "when disabling managed_by_campaign" do
      let(:rosterable) { create(:tutorial, managed_by_campaign: true) }

      context "when campaign is running" do
        before do
          campaign = create(:registration_campaign, campaignable: rosterable.lecture,
                                                    status: :draft, planning_only: false)
          create(:registration_item, registration_campaign: campaign, registerable: rosterable)
        end

        it "is invalid" do
          rosterable.managed_by_campaign = false
          expect(rosterable).not_to(be_valid)
          expect(rosterable.errors[:managed_by_campaign])
            .to(include(I18n.t("roster.errors.campaign_running")))
        end
      end

      context "when no campaign is running" do
        it "is valid" do
          rosterable.managed_by_campaign = false
          expect(rosterable).to(be_valid)
        end
      end
    end
  end
end
