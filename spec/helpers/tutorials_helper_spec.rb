require "rails_helper"

RSpec.describe(TutorialsHelper, type: :helper) do
  describe "#grading_enabled?" do
    let(:assignment) { instance_double("Assignment") }

    context "when flipper is enabled and assignment is assessable" do
      before do
        allow(Flipper).to receive(:enabled?).with(:assessment_grading).and_return(true)
        allow(assignment).to receive(:assessable?).and_return(true)
      end

      it { expect(helper.grading_enabled?(assignment)).to be(true) }
    end

    context "when flipper is disabled" do
      before do
        allow(Flipper).to receive(:enabled?).with(:assessment_grading).and_return(false)
        allow(assignment).to receive(:assessable?).and_return(true)
      end

      it { expect(helper.grading_enabled?(assignment)).to be(false) }
    end

    context "when assignment is not assessable" do
      before do
        allow(Flipper).to receive(:enabled?).with(:assessment_grading).and_return(true)
        allow(assignment).to receive(:assessable?).and_return(false)
      end

      it { expect(helper.grading_enabled?(assignment)).to be(false) }
    end
  end

  describe "#badge_status_participation_color" do
    it { expect(helper.badge_status_participation_color(:pending)).to eq("warning") }
    it { expect(helper.badge_status_participation_color(:reviewed)).to eq("success") }
    it { expect(helper.badge_status_participation_color(:exempt)).to eq("info") }
    it { expect(helper.badge_status_participation_color(:absent)).to eq("info") }
    it { expect(helper.badge_status_participation_color(nil)).to be_nil }
    it "accepts string status" do
      expect(helper.badge_status_participation_color("pending")).to eq("warning")
    end
  end

  describe "#tutorials_for_dropdown" do
    let(:lecture) { instance_double("Lecture") }
    let(:user) { instance_double("User") }
    let(:tutorial1) { instance_double("Tutorial") }
    let(:tutorial2) { instance_double("Tutorial") }
    let(:tutorial3) { instance_double("Tutorial") }
    let(:current_tutorial) { tutorial1 }

    before do
      allow(lecture).to receive(:tutorials).and_return([tutorial1, tutorial2, tutorial3])
      allow(lecture).to receive(:tutors).and_return([])
    end

    context "when user is not a tutor of the lecture" do
      before do
        allow(user).to receive(:in?).with(lecture.tutors).and_return(false)
      end

      it "returns all tutorials except current" do
        result = helper.tutorials_for_dropdown(user, lecture, current_tutorial)
        expect(result).to eq({ "All tutorials" => [tutorial2, tutorial3] })
      end
    end

    context "when user is editor or teacher" do
      before do
        allow(user).to receive(:in?).with(lecture.tutors).and_return(true)
        allow(user).to receive(:editor_or_teacher_in?).with(lecture).and_return(true)
        allow(user).to receive(:tutorials).with(lecture).and_return([tutorial1, tutorial2])
      end

      it "returns own and other tutorials excluding current" do
        result = helper.tutorials_for_dropdown(user, lecture, current_tutorial)
        expect(result).to eq({
                               "Own tutorials" => [tutorial2],
                               "Other tutorials" => [tutorial3]
                             })
      end

      it "drops empty groups" do
        allow(lecture).to receive(:tutorials).and_return([tutorial1, tutorial2])
        result = helper.tutorials_for_dropdown(user, lecture, current_tutorial)
        expect(result.key?("Other tutorials")).to be(false)
      end
    end

    context "when user is a plain tutor" do
      before do
        allow(user).to receive(:in?).with(lecture.tutors).and_return(true)
        allow(user).to receive(:editor_or_teacher_in?).with(lecture).and_return(false)
        allow(user).to receive(:tutorials).with(lecture).and_return([tutorial1, tutorial2])
      end

      it "returns only own tutorials excluding current" do
        result = helper.tutorials_for_dropdown(user, lecture, current_tutorial)
        expect(result).to eq({ "Your tutorials" => [tutorial2] })
      end
    end
  end
end
