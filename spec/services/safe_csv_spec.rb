require "rails_helper"

RSpec.describe(SafeCsv) do
  describe ".generate" do
    it "sanitizes every appended row against formula injection" do
      output = described_class.generate do |csv|
        csv << ["=cmd()", "ok", 42]
        csv << ["-1+1", "safe"]
      end

      rows = CSV.parse(output)
      expect(rows[0]).to eq(["'=cmd()", "ok", "42"])
      expect(rows[1]).to eq(["'-1+1", "safe"])
    end

    it "passes CSV options through to CSV.generate" do
      output = described_class.generate(col_sep: ";") do |csv|
        csv << ["a", "b"]
      end

      expect(output).to eq("a;b\n")
    end

    it "returns the generated CSV string" do
      output = described_class.generate { |csv| csv << ["x"] }
      expect(output).to eq("x\n")
    end
  end
end
