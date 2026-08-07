require "rails_helper"

RSpec.describe(StudentPerformance::RuleChangePreview) do
  let(:lecture) { FactoryBot.create(:lecture) }
  let(:teacher) { FactoryBot.create(:confirmed_user) }

  let(:current_rule) do
    FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                      lecture: lecture, min_percentage: 50)
  end

  let(:stricter_rule) do
    StudentPerformance::PreviewRule.new(min_percentage: 70,
                                        min_points_absolute: nil,
                                        required_achievements: Achievement.none)
  end

  def record_for(percentage)
    FactoryBot.create(:student_performance_record,
                      lecture: lecture,
                      user: FactoryBot.create(:confirmed_user),
                      points_total_materialized: percentage,
                      points_max_materialized: 100,
                      percentage_materialized: percentage)
  end

  def certify(record, source)
    FactoryBot.create(:student_performance_certification, :passed,
                      lecture: lecture, user: record.user,
                      rule: current_rule, certified_by: teacher,
                      source: source)
  end

  def preview(records, certifications = [])
    described_class.new(current_rule: current_rule,
                        preview_rule: stricter_rule,
                        records: records,
                        certifications: certifications)
  end

  describe "#changes" do
    it "names everyone the new rule would move" do
      moved = record_for(60)
      unaffected = record_for(80)

      result = preview([moved, unaffected])
      expect(result.changes.map(&:record)).to eq([moved])
      expect(result.newly(:failed)).to eq(1)
    end

    it "leaves out a decision no sweep would touch" do
      computed = record_for(60)
      by_hand = record_for(60)
      certify(computed, :computed)

      result = preview([computed, by_hand], [certify(by_hand, :manual)])
      expect(result.changes.map(&:record)).to eq([computed])
      expect(result.newly(:failed)).to eq(1)
    end

    it "counts an undecided student, since a sweep may still decide them" do
      undecided = record_for(60)

      result = preview([undecided], [certify(undecided, :computed)])
      expect(result.newly(:failed)).to eq(1)
    end
  end

  describe "#manual_conflicts" do
    it "reports the decision that stands against the new rule" do
      by_hand = record_for(60)

      result = preview([by_hand], [certify(by_hand, :manual)])
      expect(result.manual_conflicts.map(&:record)).to eq([by_hand])
      expect(result.manual_conflicts.first.from).to eq(:passed)
      expect(result.manual_conflicts.first.to).to eq(:failed)
    end

    it "stays empty when a hand-set decision is unaffected anyway" do
      by_hand = record_for(80)

      result = preview([by_hand], [certify(by_hand, :manual)])
      expect(result.manual_conflicts).to be_empty
      expect(result.changes).to be_empty
    end
  end
end
