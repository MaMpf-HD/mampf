require "rails_helper"

RSpec.describe(LectureQuickActionsComponent, type: :component) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }

  before { user.bookmark_lecture!(lecture) }

  def render_actions
    render_inline(described_class.new(lecture: lecture, user: user))
  end

  it "renders nothing when there is nothing to act on" do
    expect(render_actions.css(".quick-action")).to be_empty
  end

  describe "an assignment coming up" do
    it "points at the submission page" do
      create(:assignment, lecture: lecture, deadline: 2.days.from_now)

      action = render_actions.at_css("[data-testid='quick-action-assignment']")

      expect(action["href"]).to eq("/lectures/#{lecture.id}/submissions")
      label_prefix = I18n.t("dashboard.quick_actions.assignment.label")
                         .split("%{").first.strip
      expect(action.text).to include(label_prefix)
    end

    it "stays quiet about a deadline that is still weeks away" do
      create(:assignment, lecture: lecture, deadline: 3.weeks.from_now)

      expect(render_actions.css("[data-testid='quick-action-assignment']"))
        .to be_empty
    end
  end

  describe "a new result" do
    let(:exam) { create(:exam, lecture: lecture, title: "Main Exam") }
    let!(:participation) do
      create(:assessment_participation, assessment: exam.assessment, user: user,
                                        status: :reviewed, grade_numeric: 2.0)
    end

    it "points at the lecture home once the result is published" do
      exam.assessment.update!(results_published_at: Time.current)

      action = render_actions.at_css("[data-testid='quick-action-result']")

      expect(action["href"]).to eq("/lectures/#{lecture.id}")
      expect(action.text)
        .to include(I18n.t("dashboard.quick_actions.result.label", count: 1, title: "Main Exam"))
    end

    it "stays quiet before the result is published and after it was closed" do
      expect(render_actions.css("[data-testid='quick-action-result']")).to be_empty

      exam.assessment.update!(results_published_at: Time.current)
      participation.update!(result_seen_at: Time.current)

      expect(render_actions.css("[data-testid='quick-action-result']")).to be_empty
    end
  end

  describe "an open exam registration" do
    let(:exam) { create(:exam, :with_date, lecture: lecture) }

    before { exam.registration_campaign.update!(status: :open) }

    it "points at the lecture" do
      action = render_actions.at_css("[data-testid='quick-action-exam']")

      expect(action["href"]).to eq("/lectures/#{lecture.id}")
      expect(action.text).to include(I18n.t("dashboard.quick_actions.exam.label"))
    end

    it "stays quiet once the student has answered it" do
      create(:registration_user_registration,
             user: user,
             registration_campaign: exam.registration_campaign,
             registration_item: exam.registration_campaign
                                    .registration_items.first)

      expect(render_actions.css("[data-testid='quick-action-exam']")).to be_empty
    end
  end

  describe "unread discussion" do
    let(:activity) do
      instance_double(Dashboard::LectureActivity,
                      unread_forum_topics: 2,
                      unread_comments: 1)
    end

    it "gathers the forum and the comments into one bubble" do
      rendered = render_inline(described_class.new(lecture: lecture, user: user,
                                                   activity: activity))

      action = rendered.at_css("[data-testid='quick-action-activity']")

      expect(action.text)
        .to include(I18n.t("dashboard.quick_actions.activity.forum", count: 2))
      expect(action.text)
        .to include(I18n.t("dashboard.quick_actions.activity.comments", count: 1))
      expect(action["href"]).to eq("/lectures/#{lecture.id}")
    end
  end

  context "when the card belongs to staff or a tutor" do
    let(:activity) do
      instance_double(Dashboard::LectureActivity,
                      unread_forum_topics: 1,
                      unread_comments: 0)
    end

    def render_staff_actions
      render_inline(described_class.new(lecture: lecture, user: user,
                                        activity: activity, staff: true))
    end

    it "leaves out the student deadlines and exam registration" do
      create(:assignment, lecture: lecture, deadline: 2.days.from_now)
      exam = create(:exam, :with_date, lecture: lecture)
      exam.registration_campaign.update!(status: :open)

      rendered = render_staff_actions

      expect(rendered.css("[data-testid='quick-action-assignment']")).to be_empty
      expect(rendered.css("[data-testid='quick-action-exam']")).to be_empty
    end

    it "still shows unread discussion" do
      expect(render_staff_actions.at_css("[data-testid='quick-action-activity']"))
        .to be_present
    end
  end

  it "names the lecture inside each link, so it stands on its own" do
    create(:assignment, lecture: lecture, deadline: 2.days.from_now)

    action = render_actions.at_css("[data-testid='quick-action-assignment']")

    expect(action.css(".visually-hidden").text).to include(lecture.title_no_term)
  end

  it "labels the rail with the lecture it belongs to" do
    create(:assignment, lecture: lecture, deadline: 2.days.from_now)

    expect(render_actions.at_css("[data-testid='lecture-quick-actions']")["aria-label"])
      .to include(lecture.title_no_term)
  end
end
