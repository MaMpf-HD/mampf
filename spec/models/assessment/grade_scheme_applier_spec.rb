require "rails_helper"

RSpec.describe(Assessment::GradeSchemeApplier) do
  let(:lecture) { FactoryBot.create(:lecture) }
  let(:exam) { FactoryBot.create(:exam, lecture: lecture) }
  let(:assessment) do
    FactoryBot.create(:assessment, :for_exam,
                      assessable: exam, lecture: lecture,
                      total_points: 60)
  end
  let(:scheme) { FactoryBot.create(:assessment_grade_scheme, assessment: assessment) }
  let(:applier) { described_class.new(scheme) }
  let(:professor) { FactoryBot.create(:confirmed_user) }

  def create_reviewed_participation(points:)
    FactoryBot.create(:assessment_participation, :reviewed,
                      assessment: assessment,
                      points_total: points)
  end

  describe "#analyze_distribution" do
    it "returns empty distribution when no reviewed participations" do
      result = applier.analyze_distribution
      expect(result[:count]).to eq(0)
      expect(result[:min]).to be_nil
      expect(result[:std_dev]).to be_nil
      expect(result[:max_possible]).to eq(60)
    end

    it "computes correct statistics" do
      [20, 35, 45, 55, 60].each { |pts| create_reviewed_participation(points: pts) }

      result = applier.analyze_distribution

      expect(result[:count]).to eq(5)
      expect(result[:min]).to eq(20)
      expect(result[:max]).to eq(60)
      expect(result[:mean]).to eq(43)
      expect(result[:median]).to eq(45)
      expect(result[:std_dev]).to eq(16.05)
      expect(result[:max_possible]).to eq(60)
      expect(result[:percentiles]).to include(50)
    end

    it "computes a fractional mean correctly" do
      [20, 35].each { |pts| create_reviewed_participation(points: pts) }
      result = applier.analyze_distribution
      expect(result[:mean]).to eq(27.5)
    end
  end

  describe "#preview" do
    it "returns proposed grades without persisting" do
      p1 = create_reviewed_participation(points: 55)
      p2 = create_reviewed_participation(points: 20)

      result = applier.preview

      expect(result.size).to eq(2)

      preview_p1 = result.find { |r| r[:user_id] == p1.user_id }
      expect(preview_p1[:proposed_grade]).to eq(1.0)

      preview_p2 = result.find { |r| r[:user_id] == p2.user_id }
      expect(preview_p2[:proposed_grade]).to eq(5.0)

      expect(p1.reload.grade_numeric).to be_nil
      expect(p2.reload.grade_numeric).to be_nil
    end
  end

  describe "#apply!" do
    context "with absolute points bands" do
      it "assigns correct grades for various point totals" do
        p_excellent = create_reviewed_participation(points: 55)
        p_good = create_reviewed_participation(points: 38)
        p_pass = create_reviewed_participation(points: 24)
        p_fail = create_reviewed_participation(points: 20)

        applier.apply!(applied_by: professor)

        expect(p_excellent.reload.grade_numeric).to eq(1.0)
        expect(p_good.reload.grade_numeric).to eq(2.0)
        expect(p_pass.reload.grade_numeric).to eq(4.0)
        expect(p_fail.reload.grade_numeric).to eq(5.0)
      end

      it "assigns 1.0 for max points" do
        p = create_reviewed_participation(points: 60)
        applier.apply!(applied_by: professor)
        expect(p.reload.grade_numeric).to eq(1.0)
      end

      it "assigns 5.0 for 0 points" do
        p = create_reviewed_participation(points: 0)
        applier.apply!(applied_by: professor)
        expect(p.reload.grade_numeric).to eq(5.0)
      end

      it "handles decimal points between integer boundaries" do
        p355 = create_reviewed_participation(points: 35.5)
        p295 = create_reviewed_participation(points: 29.5)

        applier.apply!(applied_by: professor)

        expect(p355.reload.grade_numeric).to eq(2.3)
        expect(p295.reload.grade_numeric).to eq(3.7)
      end

      it "stamps applied_at and applied_by on the scheme" do
        create_reviewed_participation(points: 50)
        applier.apply!(applied_by: professor)

        scheme.reload
        expect(scheme.applied_at).to be_present
        expect(scheme.applied_by).to eq(professor)
      end

      it "stamps grader and graded_at on each participation" do
        p = create_reviewed_participation(points: 55)
        applier.apply!(applied_by: professor)

        p.reload
        expect(p.grader).to eq(professor)
        expect(p.graded_at).to be_present
        expect(p.graded_at).to eq(scheme.reload.applied_at)
      end
    end

    context "with percentage-based bands" do
      let(:pct_scheme) do
        FactoryBot.create(:assessment_grade_scheme, :percentage,
                          assessment: assessment)
      end
      let(:pct_applier) { described_class.new(pct_scheme) }

      it "assigns correct grades based on percentage" do
        p_90pct = create_reviewed_participation(points: 54)
        p_50pct = create_reviewed_participation(points: 30)
        p_low = create_reviewed_participation(points: 20)

        pct_applier.apply!(applied_by: professor)

        expect(p_90pct.reload.grade_numeric).to eq(1.0)
        expect(p_50pct.reload.grade_numeric).to eq(3.0)
        expect(p_low.reload.grade_numeric).to eq(5.0)
      end
    end

    context "idempotency" do
      it "preserves manual corrections on re-apply" do
        p = create_reviewed_participation(points: 55)
        applier.apply!(applied_by: professor)
        expect(p.reload.grade_numeric).to eq(1.0)

        p.update_column(:grade_numeric, 3.0) # rubocop:disable Rails/SkipsModelValidations

        applier.apply!(applied_by: professor)
        expect(p.reload.grade_numeric).to eq(3.0)
      end

      it "grades late-reviewed participations on re-apply" do
        p1 = create_reviewed_participation(points: 55)
        applier.apply!(applied_by: professor)
        expect(p1.reload.grade_numeric).to eq(1.0)
        original_applied_at = scheme.reload.applied_at

        p2 = create_reviewed_participation(points: 38)
        applier.apply!(applied_by: professor)
        expect(p2.reload.grade_numeric).to eq(2.0)
        expect(p1.reload.grade_numeric).to eq(1.0)
        # applied_at/applied_by record the first application, not re-applies
        expect(scheme.reload.applied_at).to eq(original_applied_at)
      end

      it "is a no-op when already applied and no ungraded participations" do
        create_reviewed_participation(points: 55)
        applier.apply!(applied_by: professor)
        original_applied_at = scheme.reload.applied_at

        applier.apply!(applied_by: professor)
        expect(scheme.reload.applied_at).to eq(original_applied_at)
      end
    end

    context "edge cases" do
      it "handles no reviewed participations gracefully" do
        FactoryBot.create(:assessment_participation, :pending,
                          assessment: assessment)

        expect { applier.apply!(applied_by: professor) }.not_to raise_error
        expect(scheme.reload.applied_at).to be_present
      end

      it "skips pending participations but grades absent as 5.0" do
        pending_p = FactoryBot.create(:assessment_participation, :pending,
                                      assessment: assessment)
        absent_p = FactoryBot.create(:assessment_participation, :absent,
                                     assessment: assessment)
        reviewed_p = create_reviewed_participation(points: 55)

        applier.apply!(applied_by: professor)

        expect(pending_p.reload.grade_numeric).to be_nil
        expect(absent_p.reload.grade_numeric).to eq(5.0)
        expect(reviewed_p.reload.grade_numeric).to eq(1.0)
      end

      it "assigns 5.0 to absent students with grader and timestamp" do
        absent_p = FactoryBot.create(:assessment_participation, :absent,
                                     assessment: assessment)
        applier.apply!(applied_by: professor)

        absent_p.reload
        expect(absent_p.grade_numeric).to eq(5.0)
        expect(absent_p.grader).to eq(professor)
        expect(absent_p.graded_at).to be_present
      end

      it "does not grade exempt participations" do
        exempt_p = FactoryBot.create(:assessment_participation, :exempt,
                                     assessment: assessment)
        applier.apply!(applied_by: professor)

        expect(exempt_p.reload.grade_numeric).to be_nil
      end

      it "preserves manually corrected absent grades on re-apply" do
        absent_p = FactoryBot.create(:assessment_participation, :absent,
                                     assessment: assessment)
        create_reviewed_participation(points: 50)
        applier.apply!(applied_by: professor)
        expect(absent_p.reload.grade_numeric).to eq(5.0)

        absent_p.update_column(:grade_numeric, 4.0) # rubocop:disable Rails/SkipsModelValidations
        applier.apply!(applied_by: professor)
        expect(absent_p.reload.grade_numeric).to eq(4.0)
      end

      it "assigns 5.0 when points_total is nil on reviewed participation" do
        p = FactoryBot.create(:assessment_participation,
                              assessment: assessment,
                              status: :reviewed,
                              points_total: nil)
        applier.apply!(applied_by: professor)
        expect(p.reload.grade_numeric).to eq(5.0)
      end
    end
  end

  describe "effective_total_points fallback" do
    let(:assessment_no_total) do
      FactoryBot.create(:assessment, :for_exam, :with_points,
                        assessable: exam, lecture: lecture,
                        total_points: nil)
    end

    it "falls back to sum of task max_points" do
      FactoryBot.create(:assessment_task, assessment: assessment_no_total,
                                          max_points: 30)
      FactoryBot.create(:assessment_task, assessment: assessment_no_total,
                                          max_points: 30)

      expect(assessment_no_total.effective_total_points).to eq(60)
    end

    it "returns 0 when no tasks and no total_points" do
      expect(assessment_no_total.effective_total_points).to eq(0)
    end
  end
end
