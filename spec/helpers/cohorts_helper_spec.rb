require "rails_helper"

RSpec.describe(CohortsHelper, type: :helper) do
  describe "#cohort_propagates?" do
    let(:lecture) { create(:lecture) }

    context "with persisted cohort" do
      it "returns true when cohort propagates" do
        cohort = create(:cohort, context: lecture, propagate_to_lecture: true)
        expect(helper.cohort_propagates?(cohort, {})).to be(true)
      end

      it "returns false when cohort does not propagate" do
        cohort = create(:cohort, context: lecture, propagate_to_lecture: false)
        expect(helper.cohort_propagates?(cohort, {})).to be(false)
      end

      it "ignores params for persisted cohorts" do
        cohort = create(:cohort, context: lecture, propagate_to_lecture: true)
        params = { cohort: { propagate_to_lecture: "false" } }
        expect(helper.cohort_propagates?(cohort, params)).to be(true)
      end
    end

    context "with new cohort" do
      let(:cohort) { build(:cohort, context: lecture) }

      it "returns true when params has propagate as 'true'" do
        params = { cohort: { propagate_to_lecture: "true" } }
        expect(helper.cohort_propagates?(cohort, params)).to be(true)
      end

      it "returns false when params has propagate as 'false'" do
        params = { cohort: { propagate_to_lecture: "false" } }
        expect(helper.cohort_propagates?(cohort, params)).to be(false)
      end

      it "returns false when params has propagate as boolean false" do
        params = { cohort: { propagate_to_lecture: false } }
        expect(helper.cohort_propagates?(cohort, params)).to be(false)
      end

      it "returns false when params is missing propagate" do
        expect(helper.cohort_propagates?(cohort, {})).to be(false)
      end
    end
  end

  describe "#cohort_special_purpose_type" do
    it "returns 'enrollment' when propagates is true" do
      expect(helper.cohort_special_purpose_type(true)).to eq("enrollment")
    end

    it "returns 'planning' when propagates is false" do
      expect(helper.cohort_special_purpose_type(false)).to eq("planning")
    end
  end

  describe "#cohort_has_special_purpose?" do
    let(:lecture) { create(:lecture) }

    it "returns true when cohort purpose matches special purpose" do
      cohort = create(:cohort, context: lecture, purpose: :enrollment,
                               propagate_to_lecture: true)
      expect(helper.cohort_has_special_purpose?(cohort, "enrollment")).to be(true)
    end

    it "returns false when cohort purpose does not match" do
      cohort = create(:cohort, context: lecture, purpose: :general)
      expect(helper.cohort_has_special_purpose?(cohort, "enrollment")).to be(false)
    end

    it "returns false when cohort has general purpose" do
      cohort = create(:cohort, context: lecture, purpose: :general)
      expect(helper.cohort_has_special_purpose?(cohort, "planning")).to be(false)
    end

    it "returns true when cohort purpose is general and checking general" do
      cohort = build(:cohort, context: lecture, purpose: :general)
      expect(helper.cohort_has_special_purpose?(cohort, "general")).to be(true)
    end
  end

  describe "#show_enrollment_warning?" do
    let(:lecture) { create(:lecture) }
    let(:cohort) { create(:cohort, context: lecture) }

    context "when propagates is true" do
      it "returns true when tutorials exist" do
        create(:tutorial, lecture: lecture)
        expect(helper.show_enrollment_warning?(cohort, true)).to be(true)
      end

      it "returns false when no tutorials or talks exist" do
        expect(helper.show_enrollment_warning?(cohort, true)).to be(false)
      end
    end

    context "when propagates is false" do
      it "returns false even when tutorials exist" do
        create(:tutorial, lecture: lecture)
        expect(helper.show_enrollment_warning?(cohort, false)).to be(false)
      end
    end

    context "with seminar" do
      let(:seminar) { create(:seminar) }
      let(:cohort) { create(:cohort, context: seminar) }

      it "returns true when propagates and talks exist" do
        create(:talk, lecture: seminar)
        expect(helper.show_enrollment_warning?(cohort, true)).to be(true)
      end
    end
  end
end
