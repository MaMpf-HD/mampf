require "rails_helper"

RSpec.describe(Registration::AvailableItemsService) do
  describe "#items" do
    context "when lecture is not a seminar" do
      let(:lecture) { create(:lecture, sort: "lecture") }
      let(:campaign) { create(:registration_campaign, campaignable: lecture) }
      let(:service) { described_class.new(campaign) }
      let!(:tutorial) { create(:tutorial, lecture: lecture) }
      let!(:cohort) { create(:cohort, context: lecture) }

      it "returns tutorials" do
        expect(service.items[:tutorials]).to include(tutorial)
      end

      it "does not return talks" do
        expect(service.items[:talks]).to be_nil
      end

      it "returns cohorts" do
        expect(service.items[:cohorts]).to include(cohort)
      end
    end

    context "when lecture is a seminar" do
      let(:lecture) { create(:lecture, :is_seminar) }
      let(:campaign) { create(:registration_campaign, campaignable: lecture) }
      let(:service) { described_class.new(campaign) }
      let!(:talk) { create(:talk, lecture: lecture) }
      let!(:cohort) { create(:cohort, context: lecture) }

      it "does not return tutorials" do
        expect(service.items[:tutorials]).to be_nil
      end

      it "returns talks" do
        expect(service.items[:talks]).to include(talk)
      end

      it "returns cohorts" do
        expect(service.items[:cohorts]).to include(cohort)
      end
    end

    context "when items are manually managed" do
      context "for regular lecture with tutorials" do
        let(:lecture) { create(:lecture, sort: "lecture") }
        let(:campaign) { create(:registration_campaign, campaignable: lecture) }
        let(:service) { described_class.new(campaign) }
        let!(:manual_tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: true) }
        let!(:auto_tutorial) { create(:tutorial, lecture: lecture, skip_campaigns: false) }

        it "does not return manually managed tutorials" do
          expect(service.items[:tutorials]).not_to include(manual_tutorial)
          expect(service.items[:tutorials]).to include(auto_tutorial)
        end
      end

      context "for seminar with talks" do
        let(:lecture) { create(:lecture, :is_seminar) }
        let(:campaign) { create(:registration_campaign, campaignable: lecture) }
        let(:service) { described_class.new(campaign) }
        let!(:manual_talk) { create(:talk, lecture: lecture, skip_campaigns: true) }
        let!(:auto_talk) { create(:talk, lecture: lecture, skip_campaigns: false) }

        it "does not return manually managed talks" do
          expect(service.items[:talks]).not_to include(manual_talk)
          expect(service.items[:talks]).to include(auto_talk)
        end
      end
    end

    context "when items are already in campaign" do
      let(:lecture) { create(:lecture, sort: "lecture") }
      let(:campaign) { create(:registration_campaign, campaignable: lecture) }
      let(:service) { described_class.new(campaign) }
      let!(:tutorial1) { create(:tutorial, lecture: lecture) }
      let!(:tutorial2) { create(:tutorial, lecture: lecture) }

      before do
        create(:registration_item, registration_campaign: campaign, registerable: tutorial1)
      end

      it "excludes already-added items" do
        expect(service.items[:tutorials]).to include(tutorial2)
        expect(service.items[:tutorials]).not_to include(tutorial1)
      end
    end

    context "when campaigns can mix item types" do
      let(:lecture) { create(:lecture, sort: "lecture") }
      let(:campaign) { create(:registration_campaign, campaignable: lecture) }
      let(:service) { described_class.new(campaign) }
      let!(:tutorial) { create(:tutorial, lecture: lecture) }
      let!(:cohort) { create(:cohort, context: lecture) }

      before do
        create(:registration_item, registration_campaign: campaign, registerable: tutorial)
      end

      it "still shows cohorts after tutorial is added" do
        expect(service.items[:cohorts]).to include(cohort)
      end
    end
  end
end
