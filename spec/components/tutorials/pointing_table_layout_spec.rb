require "rails_helper"

RSpec.describe(PointingTableLayout) do
  describe ".for" do
    it "pins a sheet's team on the left and its saving on the right" do
      layout = described_class.for(assessable: build_stubbed(:assignment))

      expect(layout.left).to eq([:team])
      expect(layout.right).to eq([:save])
    end

    it "knows no table for anything else" do
      expect { described_class.for(assessable: build_stubbed(:talk)) }
        .to raise_error(described_class::UnsupportedAssessableError)
    end
  end

  describe "#column_class" do
    let(:layout) { described_class.new(left: [:team], right: [:save]) }

    it "marks a pinned column sticky and names every column" do
      expect(layout.column_class(:team)).to eq("sticky-col team-col")
      expect(layout.column_class(:hand_in)).to eq("hand-in-col")
    end
  end

  describe "#css_vars" do
    it "hands the widths and the pins' offsets to the stylesheet" do
      layout = described_class.new(left: [:team, :status], right: [:total, :save])
      vars = layout.css_vars.split(";")

      expect(vars).to include("--team-width:200px", "--status-left:200px",
                              "--save-right:0px", "--total-right:90px",
                              "--sticky-left-width:370px", "--sticky-right-width:190px")
    end
  end
end
