require "rails_helper"

RSpec.describe(Assessment::GradeScheme, type: :model) do
  describe "factory" do
    it "creates a valid default scheme" do
      scheme = FactoryBot.create(:assessment_grade_scheme)
      expect(scheme).to be_valid
      expect(scheme.kind).to eq("banded")
      expect(scheme.active).to be(true)
      expect(scheme.applied?).to be(false)
    end

    it "creates a percentage-based scheme" do
      scheme = FactoryBot.create(:assessment_grade_scheme, :percentage)
      expect(scheme).to be_valid
      expect(scheme.config["bands"].first).to have_key("min_pct")
    end

    it "creates a draft scheme" do
      scheme = FactoryBot.create(:assessment_grade_scheme, :draft)
      expect(scheme.active).to be(false)
    end

    it "creates an applied scheme" do
      scheme = FactoryBot.create(:assessment_grade_scheme, :applied)
      expect(scheme.applied?).to be(true)
      expect(scheme.applied_by).to be_present
    end
  end

  describe "#applied?" do
    it "returns false when applied_at is nil" do
      scheme = FactoryBot.build(:assessment_grade_scheme)
      expect(scheme.applied?).to be(false)
    end

    it "returns true when applied_at is set" do
      scheme = FactoryBot.build(:assessment_grade_scheme,
                                applied_at: Time.current)
      expect(scheme.applied?).to be(true)
    end
  end

  describe "#compute_hash" do
    it "sets version_hash on save" do
      scheme = FactoryBot.create(:assessment_grade_scheme)
      expect(scheme.version_hash).to be_present
    end

    it "produces the same hash regardless of key order" do
      config = {
        "bands" => [{ "grade" => "1.0", "min_points" => 54 }]
      }
      reordered = {
        "bands" => [{ "grade" => "1.0",
                      "min_points" => 54 }]
      }
      s1 = FactoryBot.create(:assessment_grade_scheme, config: config)
      s2 = FactoryBot.create(:assessment_grade_scheme, config: reordered)
      expect(s1.version_hash).to eq(s2.version_hash)
    end

    it "updates version_hash when config changes" do
      scheme = FactoryBot.create(:assessment_grade_scheme)
      old_hash = scheme.version_hash

      new_config = scheme.config.merge(
        "bands" => scheme.config["bands"] + [
          { "min_points" => 61, "grade" => "1.0" }
        ]
      )
      scheme.update!(config: new_config)

      expect(scheme.version_hash).not_to eq(old_hash)
    end

    it "does not change version_hash when unrelated fields change" do
      scheme = FactoryBot.create(:assessment_grade_scheme)
      old_hash = scheme.version_hash
      scheme.update!(applied_at: Time.current)
      expect(scheme.version_hash).to eq(old_hash)
    end
  end

  describe "validations" do
    describe "immutability" do
      it "prevents updating an applied scheme" do
        scheme = FactoryBot.create(:assessment_grade_scheme, :applied)
        expect do
          scheme.update!(config: { "bands" => [] })
        end.to raise_error(ActiveRecord::RecordInvalid)
        expect(scheme.errors[:base]).to be_present
      end

      it "allows deactivating an applied scheme" do
        scheme = FactoryBot.create(:assessment_grade_scheme, :applied)
        expect { scheme.update!(active: false) }.not_to raise_error
      end

      it "allows updating a draft scheme" do
        scheme = FactoryBot.create(:assessment_grade_scheme, :draft)
        expect { scheme.update!(active: true) }.not_to raise_error
      end

      it "allows transitioning a draft to applied" do
        scheme = FactoryBot.create(:assessment_grade_scheme, :draft)
        user = FactoryBot.create(:confirmed_user)
        expect do
          scheme.update!(applied_at: Time.current, applied_by: user)
        end.not_to raise_error
      end
    end

    describe "config presence" do
      it "is invalid without config" do
        scheme = FactoryBot.build(:assessment_grade_scheme, config: nil)
        expect(scheme).not_to be_valid
        expect(scheme.errors[:config]).to be_present
      end
    end

    describe "config_matches_kind" do
      it "is invalid when config has no bands key" do
        scheme = FactoryBot.build(:assessment_grade_scheme, config: {})
        expect(scheme).not_to be_valid
        expect(scheme.errors[:config]).to be_present
      end

      it "is invalid when bands is empty" do
        scheme = FactoryBot.build(:assessment_grade_scheme,
                                  config: { "bands" => [] })
        expect(scheme).not_to be_valid
      end

      it "is invalid when bands have no recognized keys" do
        scheme = FactoryBot.build(:assessment_grade_scheme,
                                  config: { "bands" => [{ "grade" => "1.0" }] })
        expect(scheme).not_to be_valid
        expect(scheme.errors[:config]).to be_present
      end

      it "is invalid when bands mix min_points and min_pct" do
        mixed_config = {
          "bands" => [
            { "min_points" => 54, "grade" => "1.0" },
            { "min_pct" => 80, "max_pct" => 89.99, "grade" => "1.3" }
          ]
        }
        scheme = FactoryBot.build(:assessment_grade_scheme, config: mixed_config)
        expect(scheme).not_to be_valid
        expect(scheme.errors[:config]).to be_present
      end

      it "is invalid when a band is missing a grade" do
        config = {
          "bands" => [
            { "min_points" => 54, "grade" => "1.0" },
            { "min_points" => 0 }
          ]
        }
        scheme = FactoryBot.build(:assessment_grade_scheme, config: config)
        expect(scheme).not_to be_valid
        expect(scheme.errors[:config]).to be_present
      end

      it "is valid with absolute points bands" do
        expect(FactoryBot.build(:assessment_grade_scheme)).to be_valid
      end

      it "is valid with percentage bands" do
        expect(
          FactoryBot.build(:assessment_grade_scheme, :percentage)
        ).to be_valid
      end
    end

    describe "uniqueness of active scheme per assessment" do
      let(:assessment) { FactoryBot.create(:assessment, :for_exam) }

      it "allows only one active scheme per assessment" do
        FactoryBot.create(:assessment_grade_scheme, assessment: assessment,
                                                    active: true)
        duplicate = FactoryBot.build(:assessment_grade_scheme,
                                     assessment: assessment, active: true)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:assessment_id]).to be_present
      end

      it "allows multiple inactive schemes on the same assessment" do
        FactoryBot.create(:assessment_grade_scheme, assessment: assessment,
                                                    active: false)
        second = FactoryBot.build(:assessment_grade_scheme,
                                  assessment: assessment, active: false)
        expect(second).to be_valid
      end

      it "allows active schemes on different assessments" do
        other = FactoryBot.create(:assessment, :for_exam)
        FactoryBot.create(:assessment_grade_scheme, assessment: assessment,
                                                    active: true)
        scheme = FactoryBot.build(:assessment_grade_scheme,
                                  assessment: other, active: true)
        expect(scheme).to be_valid
      end
    end

    describe "assessable_must_be_pointable_and_gradable" do
      it "is invalid when assessable is only Pointable (Assignment)" do
        assignment_assessment = FactoryBot.create(:assessment)
        scheme = FactoryBot.build(:assessment_grade_scheme,
                                  assessment: assignment_assessment)
        expect(scheme).not_to be_valid
        expect(scheme.errors[:assessment]).to be_present
      end

      it "is invalid when assessable is only Gradable (Talk)" do
        talk_assessment = FactoryBot.create(:assessment, :gradable)
        scheme = FactoryBot.build(:assessment_grade_scheme,
                                  assessment: talk_assessment)
        expect(scheme).not_to be_valid
        expect(scheme.errors[:assessment]).to be_present
      end

      it "is valid when assessable is both Pointable and Gradable (Exam)" do
        exam_assessment = FactoryBot.create(:assessment, :for_exam)
        scheme = FactoryBot.build(:assessment_grade_scheme,
                                  assessment: exam_assessment)
        expect(scheme).to be_valid
      end
    end
  end

  describe ".two_point_auto" do
    subject(:config) do
      described_class.two_point_auto(
        excellence: excellence, passing: passing, max_points: max_points
      )
    end

    let(:excellence) { 54 }
    let(:passing) { 30 }
    let(:max_points) { 60 }

    it "returns a hash with bands key" do
      expect(config).to have_key("bands")
      expect(config["bands"]).to be_an(Array)
    end

    it "generates 11 bands covering all German grades" do
      grades = config["bands"].pluck("grade")
      expect(grades).to match_array(
        ["1.0", "1.3", "1.7", "2.0", "2.3", "2.7", "3.0", "3.3", "3.7", "4.0", "5.0"]
      )
    end

    it "assigns 1.0 starting at the excellence threshold" do
      band_one = config["bands"].find { |b| b["grade"] == "1.0" }
      expect(band_one["min_points"]).to eq(54)
    end

    it "assigns 4.0 starting at the passing threshold" do
      band_four = config["bands"].find { |b| b["grade"] == "4.0" }
      expect(band_four["min_points"]).to eq(30)
    end

    it "assigns 5.0 below the passing threshold" do
      band_five = config["bands"].find { |b| b["grade"] == "5.0" }
      expect(band_five["min_points"]).to eq(0)
    end

    it "produces strictly increasing min_points across passing grades" do
      sorted = config["bands"]
               .reject { |b| b["grade"] == "5.0" }
               .sort_by { |b| b["min_points"] }
      sorted.each_cons(2) do |lower, upper|
        expect(upper["min_points"]).to be > lower["min_points"]
      end
    end

    it "covers 0 to the excellence threshold" do
      sorted = config["bands"].sort_by { |b| b["min_points"] }
      expect(sorted.first["min_points"]).to eq(0)
      expect(sorted.last["min_points"]).to eq(54)
    end

    it "does not store max_points" do
      config["bands"].each do |band|
        expect(band).not_to have_key("max_points")
      end
    end

    it "produces a valid banded config" do
      exam_assessment = FactoryBot.create(:assessment, :for_exam,
                                          total_points: 60)
      scheme = FactoryBot.build(:assessment_grade_scheme,
                                assessment: exam_assessment,
                                config: config)
      expect(scheme).to be_valid
    end

    context "with edge case: passing = 0" do
      let(:passing) { 0 }
      let(:excellence) { 50 }
      let(:max_points) { 100 }

      it "does not include a 5.0 band" do
        grades = config["bands"].pluck("grade")
        expect(grades).not_to include("5.0")
      end

      it "assigns 4.0 starting at 0" do
        band_four = config["bands"].find { |b| b["grade"] == "4.0" }
        expect(band_four["min_points"]).to eq(0)
      end
    end

    context "with tight range" do
      let(:passing) { 28 }
      let(:excellence) { 37 }
      let(:max_points) { 40 }

      it "still generates all passing grades" do
        grades = config["bands"].pluck("grade")
        expect(grades).to include("1.0", "4.0")
      end
    end

    it "raises when excellence <= passing" do
      expect do
        described_class.two_point_auto(
          excellence: 30, passing: 30, max_points: 60
        )
      end.to raise_error(ArgumentError, /excellence must be > passing/)
    end

    it "raises when passing is negative" do
      expect do
        described_class.two_point_auto(
          excellence: 50, passing: -1, max_points: 60
        )
      end.to raise_error(ArgumentError, /passing must be >= 0/)
    end

    it "raises when excellence exceeds max_points" do
      expect do
        described_class.two_point_auto(
          excellence: 70, passing: 30, max_points: 60
        )
      end.to raise_error(ArgumentError, /excellence must be <= max_points/)
    end
  end
end
