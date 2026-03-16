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

    it "returns a dynamic number of bins between 10 and 30" do
      expect(component.bins.size).to be_between(10, 30)
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

    it "each bin has height_pct and min_height_px" do
      component.bins.each do |bin|
        expect(bin).to have_key(:height_pct)
        expect(bin).to have_key(:min_height_px)
      end
    end

    it "sets height_pct to 100 for the tallest bin" do
      max_bin = component.bins.max_by { |b| b[:count] }
      expect(max_bin[:height_pct]).to eq(100)
    end

    it "sets height_pct to 0 for empty bins" do
      empty_bin = component.bins.find { |b| b[:count].zero? }
      next unless empty_bin

      expect(empty_bin[:height_pct]).to eq(0)
    end

    it "sets min_height_px to 4 for occupied bins" do
      occupied = component.bins.select { |b| b[:count].positive? }
      occupied.each { |b| expect(b[:min_height_px]).to eq(4) }
    end

    it "sets min_height_px to 0 for empty bins" do
      empty = component.bins.select { |b| b[:count].zero? }
      empty.each { |b| expect(b[:min_height_px]).to eq(0) }
    end
  end

  describe "#max_possible" do
    it "returns the assessment total points" do
      create_reviewed(points: 50)
      expect(component.max_possible).to eq(100)
    end

    it "returns 0 when no data and no total set" do
      assessment.update!(total_points: nil)
      assessment.tasks.destroy_all
      c = described_class.new(assessment: assessment.reload)
      expect(c.max_possible).to eq(0)
    end
  end

  describe "#axis_tick_items" do
    before do
      [20, 50, 80].each { |p| create_reviewed(points: p) }
    end

    it "returns hashes with value and style keys" do
      component.axis_tick_items.each do |tick|
        expect(tick).to have_key(:value)
        expect(tick).to have_key(:style)
      end
    end

    it "positions the first tick at left: 0" do
      first = component.axis_tick_items.first
      expect(first[:style]).to include("left: 0")
    end

    it "positions the last tick at right: 0" do
      last = component.axis_tick_items.last
      expect(last[:style]).to include("right: 0")
    end

    it "positions middle ticks with translateX(-50%)" do
      middle = component.axis_tick_items[1..-2]
      middle.each do |tick|
        expect(tick[:style]).to include("translateX(-50%)")
      end
    end

    it "returns a single tick at 0 when max_possible is 0" do
      assessment.update!(total_points: nil)
      assessment.tasks.destroy_all
      c = described_class.new(assessment: assessment.reload)
      expect(c.axis_tick_items).to eq([{ value: 0, style: "left: 0;" }])
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
