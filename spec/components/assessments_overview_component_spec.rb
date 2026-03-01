require "rails_helper"

RSpec.describe(AssessmentsOverviewComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }

  after do
    Flipper.disable(:student_performance)
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

      it "accepts :rules as active tab" do
        component = described_class.new(
          lecture: lecture, active_tab: :rules
        )
        expect(component.active_tab).to eq(:rules)
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
end
