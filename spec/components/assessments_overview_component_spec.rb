require "rails_helper"

RSpec.describe(AssessmentsOverviewComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }

  after do
    Flipper.disable(:student_performance)
  end

  describe "#assessments_tab_label" do
    it "returns assignments label for regular lectures" do
      component = described_class.new(lecture: lecture)
      expect(component.assessments_tab_label).to eq(
        I18n.t("assessment.tabs.assignments")
      )
    end

    it "returns talks label for seminars" do
      seminar = create(:lecture, :released_for_all,
                       teacher: teacher, sort: "seminar")
      component = described_class.new(lecture: seminar)
      expect(component.assessments_tab_label).to eq(
        I18n.t("assessment.tabs.talks")
      )
    end
  end

  describe "#resolve_tab" do
    context "when student_performance is enabled" do
      before { Flipper.enable(:student_performance) }

      it "accepts :performance as active tab" do
        component = described_class.new(
          lecture: lecture, active_tab: :performance
        )
        expect(component.active_tab).to eq(:performance)
      end

      it "accepts :certifications as active tab" do
        component = described_class.new(
          lecture: lecture, active_tab: :certifications
        )
        expect(component.active_tab).to eq(:certifications)
      end

      it "accepts :achievements as active tab" do
        component = described_class.new(
          lecture: lecture, active_tab: :achievements
        )
        expect(component.active_tab).to eq(:achievements)
      end
    end

    context "when student_performance is disabled" do
      before { Flipper.disable(:student_performance) }

      it "falls back to :assessments when :performance is requested" do
        component = described_class.new(
          lecture: lecture, active_tab: :performance
        )
        expect(component.active_tab).to eq(:assessments)
      end

      it "falls back to :assessments when :rules is requested" do
        component = described_class.new(
          lecture: lecture, active_tab: :rules
        )
        expect(component.active_tab).to eq(:assessments)
      end

      it "falls back to :assessments when :achievements requested" do
        component = described_class.new(
          lecture: lecture, active_tab: :achievements
        )
        expect(component.active_tab).to eq(:assessments)
      end
    end

    it "defaults to :assessments when no tab is given" do
      component = described_class.new(lecture: lecture)
      expect(component.active_tab).to eq(:assessments)
    end

    it "falls back to :assessments for unknown tab values" do
      component = described_class.new(
        lecture: lecture, active_tab: :bogus
      )
      expect(component.active_tab).to eq(:assessments)
    end
  end

  describe "#visible_tabs" do
    it "always includes :assessments" do
      component = described_class.new(lecture: lecture)
      expect(component.visible_tabs).to include(:assessments)
    end

    context "when student_performance is enabled" do
      before { Flipper.enable(:student_performance) }

      it "includes all tabs in the correct order" do
        component = described_class.new(lecture: lecture)
        tabs = component.visible_tabs
        expect(tabs).to eq(
          [:assessments, :achievements, :performance,
           :certifications]
        )
      end
    end

    context "when student_performance is disabled" do
      before { Flipper.disable(:student_performance) }

      it "does not include achievements" do
        component = described_class.new(lecture: lecture)
        expect(component.visible_tabs).not_to include(:achievements)
      end
    end

    context "for a seminar with student_performance enabled" do
      before { Flipper.enable(:student_performance) }

      let(:seminar) do
        create(:lecture, :released_for_all,
               teacher: teacher, sort: "seminar")
      end

      it "only includes :assessments" do
        component = described_class.new(lecture: seminar)
        expect(component.visible_tabs).to eq([:assessments])
      end

      it "reports single_tab? as true" do
        component = described_class.new(lecture: seminar)
        expect(component.single_tab?).to be(true)
      end

      it "falls back to :assessments for :performance" do
        component = described_class.new(
          lecture: seminar, active_tab: :performance
        )
        expect(component.active_tab).to eq(:assessments)
      end
    end
  end

  describe "#single_tab?" do
    it "is false for a lecture with student_performance enabled" do
      Flipper.enable(:student_performance)
      component = described_class.new(lecture: lecture)
      expect(component.single_tab?).to be(false)
    end

    it "is true when student_performance is disabled" do
      Flipper.disable(:student_performance)
      component = described_class.new(lecture: lecture)
      expect(component.single_tab?).to be(true)
    end
  end
end
