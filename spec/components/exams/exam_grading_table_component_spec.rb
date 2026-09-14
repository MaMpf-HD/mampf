require "rails_helper"

RSpec.describe(ExamGradingTableComponent, type: :component) do
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

  describe "#possible_statuses" do
    it "returns pending and reviewed" do
      expect(component.possible_statuses).to eq(["pending", "reviewed"])
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

  describe "#layout" do
    it "builds a PointingTableLayout with table_option :grading" do
      expect(PointingTableLayout).to receive(:for).with(
        assessable: exam, grading_scope: nil, table_option: :grading
      )

      component.layout
    end

    it "memoizes the layout" do
      first = component.layout
      second = component.layout
      expect(first).to equal(second)
    end
  end

  describe "rendering" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(teacher)
    end
    context "when there are participations" do
      let(:user) { create(:confirmed_user) }
      let!(:roster_entry) { create(:exam_roster_entry, exam: exam, user: user) }

      it "renders a row for each participation" do
        rendered = render_inline(component)
        expect(rendered.css("tr[id^=grading-participation-row]").size).to eq(1)
      end
    end

    context "when there are no participations" do
      it "does not render participation rows" do
        rendered = render_inline(component)
        expect(rendered.css("tr[id^=grading-participation-row]")).to be_empty
      end
    end
  end
end
