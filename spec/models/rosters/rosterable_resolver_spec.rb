require "rails_helper"

RSpec.describe(Rosters::RosterableResolver) do
  let(:lecture) { create(:lecture) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let(:cohort) { create(:cohort, context: lecture) }

  let(:loaded_lecture) do
    Rosters::RosterableResolver.eager_load_lecture(lecture.id)
  end

  describe ".eager_load_lecture" do
    it "returns a lecture with eager-loaded associations" do
      result = Rosters::RosterableResolver.eager_load_lecture(lecture.id)
      expect(result).to eq(lecture)
      expect(result.association(:tutorials)).to be_loaded
      expect(result.association(:talks)).to be_loaded
      expect(result.association(:cohorts)).to be_loaded
    end

    it "returns nil for a non-existent id" do
      result = Rosters::RosterableResolver.eager_load_lecture(-1)
      expect(result).to be_nil
    end
  end

  describe ".resolve" do
    it "resolves a Tutorial from params" do
      params = ActionController::Parameters.new(
        type: "Tutorial", tutorial_id: tutorial.id
      )
      result = described_class.resolve(params, lecture: loaded_lecture)
      expect(result).to eq(tutorial)
    end

    it "resolves a Cohort from params" do
      params = ActionController::Parameters.new(
        type: "Cohort", cohort_id: cohort.id
      )
      result = described_class.resolve(params, lecture: loaded_lecture)
      expect(result).to eq(cohort)
    end

    it "resolves a Lecture using the eager-loaded instance" do
      params = ActionController::Parameters.new(
        type: "Lecture", id: lecture.id
      )
      result = described_class.resolve(params, lecture: loaded_lecture)
      expect(result).to eq(loaded_lecture)
    end

    it "returns nil for an invalid type" do
      params = ActionController::Parameters.new(type: "User", id: 1)
      expect(described_class.resolve(params, lecture: loaded_lecture)).to be_nil
    end

    it "returns nil for a non-existent id" do
      params = ActionController::Parameters.new(
        type: "Tutorial", tutorial_id: -1
      )
      expect(described_class.resolve(params, lecture: loaded_lecture)).to be_nil
    end

    it "falls back to :id param" do
      params = ActionController::Parameters.new(
        type: "Tutorial", id: tutorial.id
      )
      result = described_class.resolve(params, lecture: loaded_lecture)
      expect(result).to eq(tutorial)
    end
  end

  describe ".reload" do
    it "returns the eager-loaded tutorial instance" do
      result = described_class.reload(tutorial, lecture: loaded_lecture)
      expect(result.id).to eq(tutorial.id)
    end

    it "returns the lecture itself for a Lecture" do
      result = described_class.reload(lecture, lecture: loaded_lecture)
      expect(result).to eq(loaded_lecture)
    end
  end

  describe ".find_target" do
    it "finds a tutorial target scoped to the lecture" do
      result = described_class.find_target(
        tutorial.id,
        type: "Tutorial",
        lecture: loaded_lecture,
        default_type: "Tutorial"
      )
      expect(result).to eq(tutorial)
    end

    it "finds a cohort target scoped to the lecture context" do
      result = described_class.find_target(
        cohort.id,
        type: "Cohort",
        lecture: loaded_lecture,
        default_type: "Tutorial"
      )
      expect(result).to eq(cohort)
    end

    it "returns nil for a target in a different lecture" do
      other_lecture = create(:lecture)
      other_tutorial = create(:tutorial, lecture: other_lecture)
      result = described_class.find_target(
        other_tutorial.id,
        type: "Tutorial",
        lecture: loaded_lecture,
        default_type: "Tutorial"
      )
      expect(result).to be_nil
    end

    it "returns nil for an invalid type" do
      result = described_class.find_target(
        tutorial.id,
        type: "User",
        lecture: loaded_lecture,
        default_type: "Tutorial"
      )
      expect(result).to be_nil
    end
  end
end
