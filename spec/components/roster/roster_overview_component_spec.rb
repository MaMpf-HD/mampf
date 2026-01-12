require "rails_helper"

RSpec.describe(RosterOverviewComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  # Default group_type is :all
  let(:component) { described_class.new(lecture: lecture) }

  describe "#sections" do
    context "with tutorials" do
      let!(:tutorial) { create(:tutorial, lecture: lecture) }

      it "places tutorials in the main section" do
        sections = component.sections
        main_section = sections.first

        expect(main_section[:title]).to eq(I18n.t("roster.tabs.tutorial_maintenance"))
        expect(main_section[:items]).to include(tutorial)
      end
    end

    context "with talks" do
      let(:lecture) { create(:seminar) }
      let!(:talk) { create(:talk, lecture: lecture) }

      it "places talks in the main section" do
        sections = component.sections
        main_section = sections.first

        expect(main_section[:title]).to eq(I18n.t("roster.tabs.talk_maintenance"))
        expect(main_section[:items]).to include(talk)
      end
    end

    context "with cohorts" do
      let!(:enrolled_cohort) { create(:cohort, context: lecture, propagate_to_lecture: true) }
      let!(:isolated_cohort) { create(:cohort, context: lecture, propagate_to_lecture: false) }

      it "places enrolled cohorts in the main section" do
        sections = component.sections
        main_section = sections.find { |s| s[:title] == I18n.t("roster.tabs.tutorial_maintenance") }

        expect(main_section[:items]).to include(enrolled_cohort)
        expect(main_section[:items]).not_to include(isolated_cohort)
      end

      it "places isolated cohorts in the isolated section" do
        sections = component.sections
        iso_section = sections.find do |s|
          s[:title] == I18n.t("roster.cohorts.without_lecture_enrollment_title")
        end

        expect(iso_section).to be_present
        expect(iso_section[:items]).to include(isolated_cohort)
        expect(iso_section[:items]).not_to include(enrolled_cohort)
      end
    end

    context "logic when filtering by group_type" do
      let!(:tutorial) { create(:tutorial, lecture: lecture) }
      let!(:enrolled_cohort) { create(:cohort, context: lecture, propagate_to_lecture: true) }

      it "only shows requested types" do
        # Only tutorials
        comp = described_class.new(lecture: lecture, group_type: :tutorials)
        sections = comp.sections
        main_items = sections.flat_map { |s| s[:items] }

        expect(main_items).to include(tutorial)
        expect(main_items).not_to include(enrolled_cohort)
      end
    end
  end

  describe "#actions" do
    it "includes Create Tutorial action in main section" do
      sections = component.sections
      actions = sections.first[:actions]

      expect(actions).to include(include(label: Tutorial.model_name.human))
    end

    it "includes Create Enrolled Cohort action in main section" do
      sections = component.sections
      actions = sections.first[:actions]

      expect(actions).to include(include(label: I18n.t("roster.cohorts.kinds.with_enrollment")))
    end
  end

  describe "#group_path" do
    let(:helpers) { double("helpers") }

    before do
      allow(component).to receive(:helpers).and_return(helpers)
    end

    it "returns tutorial roster path for a Tutorial" do
      tutorial = create(:tutorial, lecture: lecture)
      allow(helpers).to receive(:tutorial_roster_path)
        .with(tutorial).and_return("/tutorials/#{tutorial.id}/roster")
      expect(component.group_path(tutorial)).to eq("/tutorials/#{tutorial.id}/roster")
    end
  end

  describe "#active_campaign_for" do
    let(:tutorial) { create(:tutorial, lecture: lecture) }
    let(:campaign) { create(:registration_campaign, campaignable: lecture, status: :draft) }

    before do
      create(:registration_item, registration_campaign: campaign, registerable: tutorial)
      campaign.update(status: :open)
    end

    it "returns the active campaign" do
      expect(component.active_campaign_for(tutorial)).to eq(campaign)
    end
  end

  describe "#show_skip_campaigns_switch?" do
    let(:item) { create(:tutorial, lecture: lecture) }

    it "returns true if skip_campaigns can be disabled" do
      allow(item).to receive(:skip_campaigns?).and_return(true)
      allow(item).to receive(:can_unskip_campaigns?).and_return(true)
      expect(component.show_skip_campaigns_switch?(item)).to be(true)
    end
  end
end
