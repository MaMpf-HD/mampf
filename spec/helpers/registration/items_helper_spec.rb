require "rails_helper"

RSpec.describe(Registration::ItemsHelper, type: :helper) do
  describe "#item_display_type" do
    context "for Tutorial" do
      let(:item) { double("Item", registerable_type: "Tutorial") }

      it "returns tutorial type label" do
        expect(helper.item_display_type(item)).to eq(I18n.t("registration.item.types.tutorial"))
      end
    end

    context "for Talk" do
      let(:item) { double("Item", registerable_type: "Talk", registerable: double("Talk", position: 5)) }

      it "returns talk type label with position" do
        expect(helper.item_display_type(item)).to eq("#{I18n.t("registration.item.types.talk")} 5")
      end
    end

    context "for Cohort" do
      let(:item) { double("Item", registerable_type: "Cohort", registerable: cohort) }

      context "with propagation" do
        let(:cohort) do
          double("Cohort", propagate_to_lecture: true)
        end

        it "returns group label without icon" do
          expect(helper.item_display_type(item)).to eq(I18n.t("registration.item.types.other_group"))
        end
      end

      context "without propagation" do
        let(:cohort) do
          double("Cohort", propagate_to_lecture: false)
        end

        it "returns group label with no-propagation icon" do
          result = helper.item_display_type(item)
          expect(result).to include(I18n.t("registration.item.types.other_group"))
          expect(result).to include("bi-person-x")
          expect(result).to include(I18n.t("registration.item.hints.no_propagation"))
        end
      end
    end
    
    context "for unknown type" do
      let(:item) { double("Item", registerable_type: "Unknown") }
      
      it "returns nil safely" do
        expect(helper.item_display_type(item)).to be_nil
      end
    end
  end
end
