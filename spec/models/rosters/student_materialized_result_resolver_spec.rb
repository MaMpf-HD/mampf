require "rails_helper"

RSpec.describe(Rosters::StudentMaterializedResultResolver, type: :service) do
  let(:user) { create(:user) }

  describe "#all_rosterized_for_lecture" do
    let(:lecture) { create(:lecture) }
    let!(:tutorial) do
      create(:tutorial, :with_tutors, lecture: lecture, title: "Tutorial 2")
    end
    let!(:cohort) do
      create(:cohort, context: lecture, title: "Repeaters", description: "Extra support")
    end

    before do
      create(:tutorial_membership, tutorial: tutorial, user: user)
      create(:cohort_membership, cohort: cohort, user: user)
    end

    it "returns rosterables for the lecture with their associations preloaded" do
      result = described_class.new(user).all_rosterized_for_lecture(lecture)

      expect(result).to match_array([tutorial, cohort])
      expect(result.find { |entry| entry == tutorial }.association(:tutors)).to be_loaded
      expect(result.find { |entry| entry == tutorial }.association(:members)).to be_loaded
      expect(result.find { |entry| entry == cohort }.association(:members)).to be_loaded
    end

    it "returns nil when the user has no rosterized entries for the lecture" do
      other_user = create(:user)

      result = described_class.new(other_user).all_rosterized_for_lecture(lecture)

      expect(result).to be_nil
    end
  end
end
