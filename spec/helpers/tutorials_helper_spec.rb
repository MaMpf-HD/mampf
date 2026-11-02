require "rails_helper"

RSpec.describe(TutorialsHelper, type: :helper) do
  describe "#grading_enabled?" do
    let(:assignment) { instance_double("Assignment") }

    context "when the assignment is assessable" do
      before do
        allow(assignment).to receive(:assessable?).and_return(true)
      end

      it { expect(helper.grading_enabled?(assignment)).to be(true) }
    end

    context "when assignment is not assessable" do
      before do
        allow(assignment).to receive(:assessable?).and_return(false)
      end

      it { expect(helper.grading_enabled?(assignment)).to be(false) }
    end
  end

  describe "#tutorials_for_dropdown" do
    let(:lecture) { create(:lecture) }
    let(:user) { create(:confirmed_user) }
    let!(:tutorial1) { create(:tutorial, lecture: lecture, title: "Group 1") }
    let!(:tutorial2) { create(:tutorial, lecture: lecture, title: "Group 2") }
    let!(:tutorial3) { create(:tutorial, lecture: lecture, title: "Group 3") }
    let(:current_tutorial) { tutorial1 }

    context "when user is not a tutor of the lecture" do
      it "returns all tutorials except current" do
        result = helper.tutorials_for_dropdown(user, lecture, current_tutorial)
        expect(result).to eq({ "All tutorials" => [tutorial2, tutorial3] })
      end
    end

    context "when user is editor or teacher" do
      before do
        create(:editable_user_join, user: user, editable: lecture)
        [tutorial1, tutorial2].each { |tutorial| tutorial.add_tutor(user) }
      end

      it "returns own and other tutorials excluding current" do
        result = helper.tutorials_for_dropdown(user, lecture, current_tutorial)
        expect(result).to eq({
                               "Own tutorials" => [tutorial2],
                               "Other tutorials" => [tutorial3]
                             })
      end

      it "drops empty groups" do
        tutorial3.add_tutor(user)
        result = helper.tutorials_for_dropdown(user, lecture, current_tutorial)
        expect(result.key?("Other tutorials")).to be(false)
      end
    end

    context "when user is a plain tutor" do
      before do
        [tutorial1, tutorial2].each { |tutorial| tutorial.add_tutor(user) }
      end

      it "returns only own tutorials excluding current" do
        result = helper.tutorials_for_dropdown(user, lecture, current_tutorial)
        expect(result).to eq({ "Your tutorials" => [tutorial2] })
      end
    end
  end

  describe "#tutorial_option_label" do
    let(:user) { create(:confirmed_user) }
    let(:tutor) { create(:confirmed_user, first_name: "Ada", last_name: "Lovelace") }
    let(:tutorial) { create(:tutorial, title: "Group 1") }

    it "names another group's tutors" do
      tutorial.add_tutor(tutor)
      expect(helper.tutorial_option_label(tutorial, user)).to eq("Group 1 (Ada Lovelace)")
    end

    it "leaves the viewer's own group by its title" do
      tutorial.add_tutor(user)
      expect(helper.tutorial_option_label(tutorial, user)).to eq("Group 1")
    end
  end
end
