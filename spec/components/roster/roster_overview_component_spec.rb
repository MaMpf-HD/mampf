require "rails_helper"

RSpec.describe(RosterOverviewComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  # Default group_type is :all
  let(:component) { described_class.new(lecture: lecture) }

  describe "#sections" do
    context "with tutorials" do
      let!(:tutorial) { create(:tutorial, lecture: lecture) }

      it "places tutorials in the enrollment section" do
        sections = component.sections
        main_section = sections.first

        expect(main_section[:title]).to eq(I18n.t("roster.cohorts.with_lecture_enrollment_title"))
        expect(main_section[:items]).to include(tutorial)
      end
    end

    context "with talks" do
      let(:lecture) { create(:seminar) }
      let!(:talk) { create(:talk, lecture: lecture) }

      it "places talks in the enrollment section" do
        sections = component.sections
        main_section = sections.first

        expect(main_section[:title]).to eq(I18n.t("roster.cohorts.with_lecture_enrollment_title"))
        expect(main_section[:items]).to include(talk)
      end
    end

    context "with cohorts" do
      let!(:enrolled_cohort) { create(:cohort, context: lecture, propagate_to_lecture: true) }
      let!(:isolated_cohort) { create(:cohort, context: lecture, propagate_to_lecture: false) }

      it "places enrolled cohorts in the enrollment section" do
        sections = component.sections
        main_section = sections.find do |s|
          s[:title] == I18n.t("roster.cohorts.with_lecture_enrollment_title")
        end

        expect(main_section).to be_present
        expect(main_section[:items]).to include(enrolled_cohort)
        expect(main_section[:items]).not_to include(isolated_cohort)
      end

      it "places isolated cohorts in the without enrollment section" do
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

  describe "#all_groups_empty?" do
    it "returns true when lecture has no groups" do
      expect(component.all_groups_empty?).to be(true)
    end

    it "returns false when lecture has tutorials" do
      create(:tutorial, lecture: lecture)
      expect(component.all_groups_empty?).to be(false)
    end
  end
end
