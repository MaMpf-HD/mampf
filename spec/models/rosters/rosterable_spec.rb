require "rails_helper"

RSpec.describe(Rosters::Rosterable) do
  it "ensures all including models have a manual_roster_mode attribute" do
    # Eager load the application to ensure all models are loaded and discoverable
    Rails.application.eager_load!

    models = ApplicationRecord.descendants.select do |model|
      model.included_modules.include?(described_class)
    end

    models.each do |model|
      expect(model.new)
        .to(respond_to(:manual_roster_mode), "#{model} must have a manual_roster_mode attribute")
    end
  end

  describe "#locked?" do
    let(:rosterable) { create(:tutorial, manual_roster_mode: true) }

    context "when in manual mode" do
      # manual_roster_mode: true
      it "returns false" do
        expect(rosterable.locked?).to(be(false))
      end
    end

    context "when in system mode" do
      before { rosterable.update(manual_roster_mode: false) }

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
        let(:rosterable) { create(:lecture, manual_roster_mode: false) }

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

  describe "#can_enable_manual_mode?" do
    # Was can_disable_campaign_management?
    # System -> Manual
    let(:rosterable) { create(:tutorial, manual_roster_mode: false) }

    context "when campaign is running" do
      before do
        campaign = create(:registration_campaign, campaignable: rosterable.lecture, status: :draft,
                                                  planning_only: false)
        create(:registration_item, registration_campaign: campaign, registerable: rosterable)
        campaign.update(status: :open)
      end

      it "returns false" do
        expect(rosterable.can_enable_manual_mode?).to(be(false))
      end
    end

    context "when no campaign is running" do
      it "returns true" do
        expect(rosterable.can_enable_manual_mode?).to(be(true))
      end
    end
  end

  describe "validations" do
    # Switching Manual -> System (enabling managed_by_campaign)
    # Corresponds to manual_roster_mode: true -> false
    context "when disabling manual_roster_mode" do
      let(:rosterable) { create(:tutorial, manual_roster_mode: true) }

      context "when roster is empty" do
        it "is valid" do
          rosterable.manual_roster_mode = false
          expect(rosterable).to(be_valid)
        end
      end

      context "when roster is not empty" do
        before do
          rosterable.add_user_to_roster!(create(:user))
        end

        it "is invalid" do
          rosterable.manual_roster_mode = false
          expect(rosterable).not_to(be_valid)
          expect(rosterable.errors[:manual_roster_mode])
            .to(include(I18n.t("roster.errors.roster_not_empty")))
        end
      end
    end

    # Switching System -> Manual (disabling managed_by_campaign)
    # Corresponds to manual_roster_mode: false -> true
    context "when enabling manual_roster_mode" do
      let(:rosterable) { create(:tutorial, manual_roster_mode: false) }

      context "when campaign is running" do
        before do
          campaign = create(:registration_campaign, campaignable: rosterable.lecture,
                                                    status: :draft, planning_only: false)
          create(:registration_item, registration_campaign: campaign, registerable: rosterable)
        end

        it "is invalid" do
          rosterable.manual_roster_mode = true
          expect(rosterable).not_to(be_valid)
          expect(rosterable.errors[:manual_roster_mode])
            .to(include(I18n.t("roster.errors.campaign_associated")))
        end
      end

      context "when no campaign is running" do
        it "is valid" do
          rosterable.manual_roster_mode = true
          expect(rosterable).to(be_valid)
        end
      end
    end
  end
end
