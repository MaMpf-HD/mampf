require "rails_helper"

RSpec.describe(DistributionAnalysisComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher) }
  let(:exam) { create(:exam, lecture: lecture) }
  let(:assessment) do
    exam.reload.assessment.tap { |a| a.update!(total_points: 100) }
  end

  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  let(:component) { described_class.new(assessment: assessment) }

  def create_reviewed(points:)
    create(:assessment_participation, :reviewed,
           assessment: assessment, points_total: points)
  end

  describe "#distribution" do
    context "with no reviewed participations" do
      it "returns empty distribution" do
        expect(component.distribution[:count]).to eq(0)
      end
    end

    context "with reviewed participations" do
      before do
        [20, 40, 60, 80, 90].each { |p| create_reviewed(points: p) }
      end

      it "returns correct count" do
        expect(component.distribution[:count]).to eq(5)
      end

      it "includes std_dev" do
        expect(component.distribution[:std_dev]).to be_a(Float)
        expect(component.distribution[:std_dev]).to be > 0
      end
    end
  end

  describe "#bins" do
    before do
      [10, 25, 55, 55, 75, 90].each { |p| create_reviewed(points: p) }
    end

    it "returns BIN_COUNT bins" do
      expect(component.bins.size).to eq(described_class::BIN_COUNT)
    end

    it "assigns students to correct bins" do
      total_in_bins = component.bins.sum { |b| b[:count] }
      expect(total_in_bins).to eq(6)
    end

    it "each bin has low, high, and count" do
      component.bins.each do |bin|
        expect(bin).to have_key(:low)
        expect(bin).to have_key(:high)
        expect(bin).to have_key(:count)
      end
    end
  end

  describe "#empty?" do
    it "returns true with no data" do
      expect(component.empty?).to be(true)
    end

    it "returns false with data" do
      create_reviewed(points: 50)
      expect(component.empty?).to be(false)
    end
  end

  describe "rendering" do
    context "when empty" do
      it "shows no-data message" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.distribution.no_data")
        )
      end

      it "does not render histogram" do
        render_inline(component)
        expect(rendered_content).not_to include(
          I18n.t("assessment.distribution.histogram_title")
        )
      end
    end

    context "with reviewed participations" do
      before do
        [20, 35, 45, 55, 60, 75, 80, 90].each do |p|
          create_reviewed(points: p)
        end
      end

      it "renders the distribution title" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.distribution.title")
        )
      end

      it "renders the histogram" do
        render_inline(component)
        expect(rendered_content).to include("data-bs-toggle=\"tooltip\"")
      end

      it "renders inline statistics" do
        render_inline(component)
        expect(rendered_content).to include("&sigma;")
        expect(rendered_content).to include("&empty;")
      end

      it "includes histogram bars with tooltips" do
        render_inline(component)
        expect(rendered_content).to include("data-bs-toggle=\"tooltip\"")
      end
    end
  end
end
