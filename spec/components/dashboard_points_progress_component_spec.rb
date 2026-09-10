require "rails_helper"

RSpec.describe(DashboardPointsProgressComponent, type: :component) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }

  def render_bar
    render_inline(described_class.new(lecture: lecture, user: user))
  end

  # A sheet that is over and worth `points`, so that it counts towards what is
  # reachable so far.
  def expired_assignment(points)
    assignment = create(:assignment, :expired, lecture: lecture)
    create(:assessment_task, assessment: assignment.assessment,
                             max_points: points)
    assignment
  end

  it "renders nothing while every assignment is still running" do
    create(:assignment, lecture: lecture, deadline: 3.days.from_now)

    expect(render_bar.css(".dashboard-progress")).to be_empty
  end

  it "renders nothing when nothing that is over carried points" do
    create(:assignment, :expired, lecture: lecture)

    expect(render_bar.css(".dashboard-progress")).to be_empty
  end

  it "counts only what is already due" do
    expired_assignment(20)
    coming = create(:assignment, lecture: lecture, deadline: 3.days.from_now)
    create(:assessment_task, assessment: coming.assessment, max_points: 30)
    create(:student_performance_record, lecture: lecture, user: user,
                                        points_total_materialized: 10)

    rendered = render_bar

    expect(rendered.at_css(".dashboard-progress__value").text.strip)
      .to eq(I18n.t("dashboard.points_progress.label", points: "10", max: "20",
                    percentage: 50))
    expect(rendered.at_css(".dashboard-progress__fill")["style"])
      .to eq("width: 50%")
  end

  it "starts at zero for a student nobody has marked yet" do
    expired_assignment(20)

    expect(render_bar.at_css(".dashboard-progress__fill")["style"])
      .to eq("width: 0%")
  end

  it "keeps the bar inside the track when bonus points overshoot it" do
    expired_assignment(20)
    create(:student_performance_record, lecture: lecture, user: user,
                                        points_total_materialized: 25)

    expect(render_bar.at_css(".dashboard-progress__fill")["style"])
      .to eq("width: 100%")
  end
end
