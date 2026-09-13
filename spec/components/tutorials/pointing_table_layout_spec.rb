require "rails_helper"

RSpec.describe(PointingTableLayout) do
  describe ".for" do
    it "gives a sheet its tasks, and the team and the saving as pins" do
      layout = described_class.for(assessable: build_stubbed(:assignment))

      expect(layout.body).to eq(:tasks)
      expect(layout.left).to eq([:team])
      expect(layout.right).to eq([:save])
    end

    it "adds the tutorial column in the lecture's table only" do
      assignment = build_stubbed(:assignment)

      expect(described_class.for(assessable: assignment).show?(:tutorial)).to be(false)
      expect(described_class.for(assessable: assignment, grading_scope: build_stubbed(:lecture))
                            .show?(:tutorial)).to be(true)
    end

    it "leaves a sheet without an assessment its file columns only" do
      layout = described_class.for(assessable: build_stubbed(:assignment))

      expect(layout.columns).to eq([:team, :hand_in, :correction])
    end

    it "gives a talk a single grade" do
      layout = described_class.for(assessable: build_stubbed(:talk))

      expect(layout.body).to eq(:single_grade)
      expect(layout.columns).to eq([:talk, :team, :status, :grade, :note, :graded, :save])
      expect(layout.left).to eq([:talk, :team])
    end

    it "knows no table for anything else" do
      expect { described_class.for(assessable: build_stubbed(:exam)) }
        .to raise_error(described_class::UnsupportedAssessableError)
    end
  end

  describe "#column_class" do
    let(:layout) { described_class.new(columns: [:team, :hand_in, :save], body: :tasks) }

    it "marks a pinned column sticky and names every column" do
      expect(layout.column_class(:team)).to eq("sticky-col team-col")
      expect(layout.column_class(:hand_in)).to eq("hand-in-col")
    end
  end

  describe "#css_vars" do
    it "hands the widths and the pins' offsets to the stylesheet" do
      layout = described_class.new(columns: [], body: :tasks,
                                   left: [:team, :status], right: [:total, :save])
      vars = layout.css_vars.split(";")

      expect(vars).to include("--team-width:200px", "--status-left:200px",
                              "--save-right:0px", "--total-right:90px",
                              "--sticky-left-width:370px", "--sticky-right-width:190px")
    end
  end
end
