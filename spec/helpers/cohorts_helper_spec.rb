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

      it "returns true when params is missing propagate" do
        expect(helper.cohort_propagates?(cohort, {})).to be(true)
      end
    end
  end
end
