require "rails_helper"

# Missing top-level docstring, please formulate one yourself 😁
RSpec.describe(Registration::ItemsHelper, type: :helper) do
  describe "#format_capacity" do
    it "returns unlimited for nil capacity" do
      expect(helper.format_capacity(nil)).to eq(I18n.t("basics.unlimited"))
    end

    it "returns formatted string for integer capacity" do
      expect(helper.format_capacity(10)).to eq("10 #{I18n.t("basics.seats")}")
    end
  end

  describe "#item_display_type" do
    let(:campaign) { create(:registration_campaign) }

    context "for Tutorial" do
      let(:item) { create(:registration_item, :for_tutorial, registration_campaign: campaign) }

      it "returns tutorial type label" do
        expect(helper.item_display_type(item))
          .to eq(I18n.t("registration.item.types.tutorial"))
      end
    end

    context "for Talk" do
      let(:item) { create(:registration_item, :for_talk) }

      it "returns talk type label" do
        expect(helper.item_display_type(item))
          .to eq(I18n.t("registration.item.types.talk"))
      end
    end

    context "for Cohort" do
      context "with enrollment purpose and propagation" do
        let(:cohort) do
          create(:cohort, context: campaign.campaignable,
                          purpose: :enrollment, propagate_to_lecture: true)
        end
        let(:item) do
          create(:registration_item, registration_campaign: campaign, registerable: cohort)
        end

        it "returns enrollment group label without icon" do
          expect(helper.item_display_type(item))
            .to eq(I18n.t("registration.item.types.enrollment_group"))
        end
      end

      context "with planning purpose (no propagation)" do
        let(:cohort) do
          create(:cohort, context: campaign.campaignable,
                          purpose: :planning, propagate_to_lecture: false)
        end
        let(:item) do
          create(:registration_item, registration_campaign: campaign, registerable: cohort)
        end

        it "returns planning survey label with no-propagation icon" do
          result = helper.item_display_type(item)
          expect(result).to include(I18n.t("registration.item.types.planning_survey"))
          expect(result).to include("bi-person-x")
          expect(result).to include(I18n.t("registration.item.hints.no_propagation"))
        end
      end

      context "with general purpose and propagation" do
        let(:cohort) do
          create(:cohort, context: campaign.campaignable,
                          purpose: :general, propagate_to_lecture: true)
        end
        let(:item) do
          create(:registration_item, registration_campaign: campaign, registerable: cohort)
        end

        it "returns other group label without icon" do
          expect(helper.item_display_type(item))
            .to eq(I18n.t("registration.item.types.other_group"))
        end
      end

      context "with general purpose without propagation" do
        let(:cohort) do
          create(:cohort, context: campaign.campaignable,
                          purpose: :general, propagate_to_lecture: false)
        end
        let(:item) do
          create(:registration_item, registration_campaign: campaign, registerable: cohort)
        end

        it "returns other group label with no-propagation icon" do
          result = helper.item_display_type(item)
          expect(result).to include(I18n.t("registration.item.types.other_group"))
          expect(result).to include("bi-person-x")
          expect(result).to include(I18n.t("registration.item.hints.no_propagation"))
        end
      end
    end
  end
end
