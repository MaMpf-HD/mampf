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
end
