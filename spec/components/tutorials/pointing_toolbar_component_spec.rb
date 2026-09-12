require "rails_helper"

RSpec.describe(PointingToolbarComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher) }
  let(:tutorial) { create(:tutorial, lecture: lecture, title: "Tuesday group") }
  let(:assignment) { create(:assignment, :expired, lecture: lecture) }

  def toolbar(scope:, statuses: [], submissions: [], tutorials: [])
    described_class.new(assignment: assignment, grading_scope: scope, statuses: statuses,
                        submissions: submissions, tutorials: tutorials)
  end

  before { allow(vc_test_controller).to receive(:current_user).and_return(teacher) }

  around { |example| I18n.with_locale(:en) { example.run } }

  describe "#status_options" do
    it "offers the states a sheet with files can show" do
      expect(toolbar(scope: tutorial).status_options.map(&:first))
        .to eq(["reviewed", "pending_grading", "not_submitted", "exempt"])
    end

    it "offers 'not yet recorded' instead of 'not submitted' for a sheet collected on paper" do
      assignment.assessment.update_column(:requires_submission, false) # rubocop:disable Rails/SkipsModelValidations

      expect(toolbar(scope: tutorial).status_options.map(&:first))
        .to eq(["reviewed", "pending_grading", "awaiting_record", "exempt"])
    end
  end

  describe "the lecture's table" do
    it "filters by group, including the people in none" do
      rendered = render_inline(toolbar(scope: lecture, tutorials: [tutorial]))

      options = rendered.css("select[data-status-filter-target=tutorial] option")

      expect(options.map { |option| option.text.strip })
        .to eq(["All", "Tuesday group", "No tutorial"])
    end

    it "has no menu of group actions" do
      rendered = render_inline(toolbar(scope: lecture, tutorials: [tutorial]))

      expect(rendered.text).not_to include(I18n.t("assessment.grading_tutorial.more_actions"))
      expect(rendered.text).to include(I18n.t("assessment.grading_tutorial.save_all"))
    end
  end

  describe "the group's table" do
    it "has no group filter" do
      rendered = render_inline(toolbar(scope: tutorial))

      expect(rendered.css("select[data-status-filter-target=tutorial]")).to be_empty
    end

    it "offers the downloads once there are files" do
      submission = create(:submission, :with_manuscript, assignment: assignment,
                                                         tutorial: tutorial,
                                                         users: [create(:confirmed_user)])
      rendered = render_inline(toolbar(scope: tutorial, submissions: [submission]))

      expect(rendered.text).to include(I18n.t("submission.bulk_download_submissions"))
      expect(rendered.text).not_to include(I18n.t("submission.bulk_download_corrections"))
      expect(rendered.text).not_to include(I18n.t("submission.bulk_upload"))
    end

    it "offers the upload to the group's tutor" do
      tutorial.tutors << teacher
      submission = create(:submission, :with_manuscript, assignment: assignment,
                                                         tutorial: tutorial,
                                                         users: [create(:confirmed_user)])
      rendered = render_inline(toolbar(scope: tutorial, submissions: [submission]))

      expect(rendered.text).to include(I18n.t("submission.bulk_upload"))
    end
  end

  it "shows no saving to somebody who may not enter points" do
    allow(vc_test_controller).to receive(:current_user).and_return(create(:confirmed_user))
    rendered = render_inline(toolbar(scope: tutorial))

    expect(rendered.text).not_to include(I18n.t("assessment.grading_tutorial.save_all"))
    expect(rendered.css("form#paper-hand-ins")).to be_empty
  end
end
