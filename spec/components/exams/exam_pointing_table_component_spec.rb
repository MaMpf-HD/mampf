require "rails_helper"

RSpec.describe(ExamPointingTableComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:exam) { create(:exam, lecture: lecture) }
  let!(:assessment) { create(:assessment, requires_points: true, assessable: exam) }

  let(:component) { described_class.new(exam: exam) }

  before do
    exam.reload
    assessment.reload
  end

  describe "#grading_enabled?" do
    context "when the exam is assessable" do
      it "returns true" do
        expect(component.grading_enabled?).to eq(true)
      end
    end

    context "when the exam is not assessable" do
      before { allow(exam).to receive(:assessable?).and_return(false) }

      it "returns false" do
        expect(component.grading_enabled?).to eq(false)
      end
    end
  end

  describe "#tasks" do
    let!(:task) { create(:assessment_task, assessment: assessment) }

    it "returns the persisted tasks from the exam's assessment" do
      expect(component.tasks).to eq(exam.reload.assessment.persisted_tasks)
    end

    context "when the exam has no assessment" do
      before { allow(exam).to receive(:assessment).and_return(nil) }

      it "returns an empty array" do
        expect(component.tasks).to eq([])
      end
    end
  end

  describe "#total_max_points" do
    it "returns the assessment's effective total points" do
      allow(assessment).to receive(:effective_total_points).and_return(42)
      allow(exam).to receive(:assessment).and_return(assessment)

      expect(component.total_max_points).to eq(42)
    end

    context "when the exam has no assessment" do
      before { allow(exam).to receive(:assessment).and_return(nil) }

      it "returns 0" do
        expect(component.total_max_points).to eq(0)
      end
    end
  end

  describe "#grading_records?" do
    context "when there are roster entries" do
      let(:user) { create(:confirmed_user) }
      let!(:roster_entry) { create(:exam_roster_entry, exam: exam, user: user) }

      it "returns true" do
        expect(component.grading_records?).to be(true)
      end
    end

    context "when there are no roster entries" do
      it "returns false" do
        expect(component.grading_records?).to be(false)
      end
    end
  end

  describe "#row_statuses" do
    let(:user) { create(:confirmed_user) }
    let!(:roster_entry) { create(:exam_roster_entry, exam: exam, user: user) }

    it "reflects the display_status of each participation" do
      Timecop.travel(1.hour.from_now) do
        Assessment::Participation.find_by(assessment: assessment, user: user)
                                 &.update!(status: :reviewed) ||
          create(:assessment_participation, :reviewed, assessment: assessment, user: user)
      end

      expect(component.row_statuses).to include(:reviewed)
    end

    it "reads a roster entry with no participation as not submitted" do
      expect(component.row_statuses).to eq([:not_submitted])
    end
  end

  describe "#summary" do
    it "returns a PointingSummaryComponent built from row_statuses" do
      summary = component.summary
      expect(summary).to be_a(PointingSummaryComponent)
    end
  end

  describe "participations" do
    let(:user) { create(:confirmed_user) }
    let!(:roster_entry) { create(:exam_roster_entry, exam: exam, user: user) }

    it "creates a participation for each roster entry that has none" do
      expect do
        described_class.new(exam: exam)
      end.to change(Assessment::Participation, :count).by(1)
    end

    it "reuses an existing participation instead of duplicating it" do
      existing = create(:assessment_participation, assessment: assessment, user: user)

      expect do
        described_class.new(exam: exam)
      end.not_to change(Assessment::Participation, :count)

      new_component = described_class.new(exam: exam)
      expect(new_component.instance_variable_get(:@participations)).to include(existing)
    end

    context "when there are multiple roster entries" do
      let(:user2) { create(:confirmed_user) }
      let!(:roster_entry2) { create(:exam_roster_entry, exam: exam, user: user2) }

      it "creates one participation per roster entry" do
        expect do
          described_class.new(exam: exam)
        end.to change(Assessment::Participation, :count).by(2)
      end
    end
  end

  describe "rendering" do
    context "when there are participations" do
      let(:user) { create(:confirmed_user) }
      let!(:roster_entry) { create(:exam_roster_entry, exam: exam, user: user) }

      it "renders the pointing table" do
        render_inline(component)
        expect(rendered_content).to include("pointing-table")
      end

      it "renders a row for each participation" do
        rendered = render_inline(component)
        expect(rendered.css("tr[id^=pointing-participation-row]").size).to eq(1)
      end
    end

    context "when there are no participations" do
      it "does not render participation rows" do
        rendered = render_inline(component)
        expect(rendered.css("tr[id^=pointing-participation-row]")).to be_empty
      end
    end
  end
end
