require "rails_helper"

RSpec.describe(Registration::AvailableItemsService) do
  let(:lecture) { create(:lecture) }
  let(:campaign) { create(:registration_campaign, campaignable: lecture) }
  let(:service) { described_class.new(campaign) }

  describe "#items" do
    context "when campaign has no items" do
      let!(:tutorial) { create(:tutorial, lecture: lecture) }
      let!(:talk) { create(:talk, lecture: lecture) }
      let!(:cohort) { create(:cohort, context: lecture) }

      it "returns all available tutorials" do
        expect(service.items[:tutorials]).to include(tutorial)
      end

      it "returns all available talks" do
        expect(service.items[:talks]).to include(talk)
      end

      it "returns all available cohorts" do
        expect(service.items[:cohorts]).to include(cohort)
      end
    end

    context "when campaign has tutorial items" do
      let!(:tutorial1) { create(:tutorial, lecture: lecture) }
      let!(:tutorial2) { create(:tutorial, lecture: lecture) }

      before do
        create(:registration_item, registration_campaign: campaign, registerable: tutorial1)
      end

      it "returns remaining tutorials" do
        expect(service.items[:tutorials]).to include(tutorial2)
        expect(service.items[:tutorials]).not_to include(tutorial1)
      end

      it "does not return talks" do
        create(:talk, lecture: lecture)
        expect(service.items[:talks]).to be_nil
      end

      it "does not return cohorts" do
        create(:cohort, context: lecture)
        expect(service.items[:cohorts]).to be_nil
      end
    end

    context "when campaign has talk items" do
      let!(:talk1) { create(:talk, lecture: lecture) }
      let!(:talk2) { create(:talk, lecture: lecture) }

      before do
        create(:registration_item, registration_campaign: campaign, registerable: talk1)
      end

      it "returns remaining talks" do
        expect(service.items[:talks]).to include(talk2)
        expect(service.items[:talks]).not_to include(talk1)
      end

      it "does not return tutorials" do
        create(:tutorial, lecture: lecture)
        expect(service.items[:tutorials]).to be_nil
      end

      it "does not return cohorts" do
        create(:cohort, context: lecture)
        expect(service.items[:cohorts]).to be_nil
      end
    end

    context "when campaign has lecture item" do
      before do
        create(:registration_item, registration_campaign: campaign, registerable: lecture)
      end

      it "returns nothing" do
        create(:tutorial, lecture: lecture)
        create(:talk, lecture: lecture)
        expect(service.items).to be_empty
      end
    end

    context "when campaign has cohort items" do
      let!(:cohort1) { create(:cohort, context: lecture) }
      let!(:cohort2) { create(:cohort, context: lecture) }

      before do
        create(:registration_item, registration_campaign: campaign, registerable: cohort1)
      end

      it "returns remaining cohorts" do
        expect(service.items[:cohorts]).to include(cohort2)
        expect(service.items[:cohorts]).not_to include(cohort1)
      end

      it "does not return tutorials" do
        create(:tutorial, lecture: lecture)
        expect(service.items[:tutorials]).to be_nil
      end

      it "does not return talks" do
        create(:talk, lecture: lecture)
        expect(service.items[:talks]).to be_nil
      end
    end
  end
end
