require "rails_helper"

RSpec.describe(NewResultsComponent, type: :component) do
  around { |example| I18n.with_locale(:en) { example.run } }

  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture) }
  let(:exam) { create(:exam, lecture: lecture, title: "Main Exam") }
  let!(:task) { create(:assessment_task, assessment: exam.assessment, max_points: 10) }
  let!(:participation) do
    create(:assessment_participation, assessment: exam.assessment, user: user)
  end

  before do
    create(:assessment_task_point, assessment_participation: participation, task: task, points: 7)
    participation.update!(status: :reviewed, points_total: 7, grade_numeric: 2.0)
    exam.assessment.update!(results_published_at: Time.current)
  end

  def render_block
    render_inline(described_class.new(lecture: lecture, user: user))
  end

  it "puts the grade up front, with the points per problem open" do
    block = render_block.at_css("[data-testid=lecture-home-new-result]")

    expect(block.text.squish).to include("Your result in Main Exam")
    expect(block.at_css(".lecture-home-new-result-value").text.squish).to eq("2.0")
    expect(block.text.squish).to include("7 of 10 points")
    expect(block.at_css("details[open]")).to be_present
    expect(block.css("button").map { |button| button.text.squish }).to eq(["Close"])
  end

  it "says so for a student who did not take part" do
    participation.update!(status: :absent, grade_numeric: 5.0, points_total: nil)
    participation.task_points.destroy_all

    block = render_block.at_css("[data-testid=lecture-home-new-result]")

    expect(block.at_css(".lecture-home-new-result-value").text.squish).to eq("Did not take part")
    expect(block.text.squish).to include("Grade 5.0")
  end

  it "is gone once the student has closed it" do
    participation.update!(result_seen_at: Time.current)

    expect(render_block.text).to be_blank
  end
end
