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

    it "matches MD5 of config JSON" do
      scheme = FactoryBot.create(:assessment_grade_scheme)
      expected = Digest::MD5.hexdigest(scheme.config.to_json)
      expect(scheme.version_hash).to eq(expected)
    end

    it "updates version_hash when config changes" do
      scheme = FactoryBot.create(:assessment_grade_scheme)
      old_hash = scheme.version_hash

      new_config = scheme.config.merge(
        "bands" => scheme.config["bands"] + [
          { "min_points" => 61, "max_points" => 70, "grade" => "1.0" }
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
            { "min_points" => 54, "max_points" => 60, "grade" => "1.0" },
            { "min_pct" => 80, "max_pct" => 89.99, "grade" => "1.3" }
          ]
        }
        scheme = FactoryBot.build(:assessment_grade_scheme, config: mixed_config)
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
      let(:assessment) { FactoryBot.create(:assessment) }

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
        other = FactoryBot.create(:assessment)
        FactoryBot.create(:assessment_grade_scheme, assessment: assessment,
                                                    active: true)
        scheme = FactoryBot.build(:assessment_grade_scheme,
                                  assessment: other, active: true)
        expect(scheme).to be_valid
      end
    end
  end
end
