require "rails_helper"

RSpec.describe(CsvSafe) do
  describe ".cell" do
    it "neutralizes values starting with a formula trigger" do
      ["=cmd|'/c calc'!A1", "+1+1", "-2+3", "@SUM(A1:A9)"].each do |payload|
        expect(described_class.cell(payload)).to eq("'#{payload}")
      end
    end

    it "neutralizes a leading tab or carriage return" do
      expect(described_class.cell("\t=1+1")).to eq("'\t=1+1")
      expect(described_class.cell("\r=1+1")).to eq("'\r=1+1")
    end

    it "leaves harmless strings unchanged" do
      ["Alice, Bob", "Mustermann", "a=b+c", "3.14"].each do |value|
        expect(described_class.cell(value)).to eq(value)
      end
    end

    it "passes through non-string values unchanged" do
      expect(described_class.cell(42)).to eq(42)
      expect(described_class.cell(3.14)).to eq(3.14)
      expect(described_class.cell(nil)).to be_nil
    end
  end

  describe ".row" do
    it "sanitizes each cell of the row" do
      expect(described_class.row(["=evil()", 5, "ok"])).to eq(["'=evil()", 5, "ok"])
    end
  end
end
