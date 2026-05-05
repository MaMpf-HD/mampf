require "rails_helper"

RSpec.describe(ExamRegistrationTabComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }

  before do
    Flipper.enable(:registration_campaigns)
  end

  after do
    Flipper.disable(:registration_campaigns)
  end

  it "renders a disabled deadline field for a closed campaign" do
    exam = create(:exam, :with_date, lecture: lecture)
    exam.registration_campaign.update!(status: :closed)

    render_inline(described_class.new(exam: exam))

    document = Nokogiri::HTML.fragment(rendered_content)
    deadline_input = document.at_css("#exam_registration_deadline")

    expect(deadline_input).to be_present
    expect(deadline_input["disabled"]).to eq("disabled")
    expect(rendered_content).to include(I18n.t("registration.policy.index.title"))
  end

  it "renders the registrations table for a closed campaign before review opens" do
    exam = create(:exam, :with_date, lecture: lecture)
    campaign = exam.registration_campaign
    campaign.update!(status: :closed)
    create(:registration_user_registration, :confirmed,
           registration_campaign: campaign,
           registration_item: campaign.registration_items.first)

    render_inline(described_class.new(exam: exam))

    document = Nokogiri::HTML.fragment(rendered_content)
    workspace = document.at_css(".exam-registration-allocation-workspace")
    registrants_shell = document.at_css(".exam-registration-registrants-shell")

    expect(workspace).to be_present
    expect(registrants_shell).to be_present
    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.filter_placeholder")
    )
    expect(registrants_shell.text.squish).to include(
      I18n.t("assessment.registration_tab.closed_review_hint")
    )
    expect(rendered_content).not_to include(I18n.t("basics.actions"))
    expect(document.css("button[title]")).to be_empty
  end

  it "renders the review hint during open registrations" do
    exam = create(:exam, :with_date, lecture: lecture)
    campaign = exam.registration_campaign
    campaign.update!(status: :open, registration_deadline: 1.week.from_now)

    render_inline(described_class.new(exam: exam))

    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.open_review_hint")
    )
  end

  it "does not render rejected registrations before finalization" do
    exam = create(:exam, :with_date, lecture: lecture)
    campaign = exam.registration_campaign
    campaign.update!(status: :closed)
    rejected_user = create(:confirmed_user)
    create(:registration_user_registration,
           :rejected,
           registration_campaign: campaign,
           registration_item: campaign.registration_items.first,
           user: rejected_user,
           rejection_reason_type: Registration::UserRegistration::REJECTION_REASON_TYPE_MANUAL,
           rejection_reason_code: Registration::UserRegistration::REJECTION_REASON_CODE_WITHDRAWN_BY_TEACHER,
           rejection_reason_label: I18n.t(
             "registration.user_registration.reason_labels.withdrawn_by_teacher"
           ))

    render_inline(described_class.new(exam: exam))

    document = Nokogiri::HTML.fragment(rendered_content)

    expect(rendered_content).not_to include(
      I18n.t("assessment.registration_tab.not_on_roster_heading")
    )
    expect(rendered_content).not_to include(rejected_user.email)
    expect(document.css("button[title]")).to be_empty
  end

  it "renders unified not-on-roster reasons after finalization" do
    exam = create(:exam, :with_date, lecture: lecture)
    campaign = exam.registration_campaign
    campaign.update!(status: :completed)
    rejected_user = create(:confirmed_user)
    excluded_user = create(:confirmed_user)
    create(:registration_user_registration,
           :rejected,
           registration_campaign: campaign,
           registration_item: campaign.registration_items.first,
           user: rejected_user,
           rejection_reason_type: Registration::UserRegistration::REJECTION_REASON_TYPE_MANUAL,
           rejection_reason_code: Registration::UserRegistration::REJECTION_REASON_CODE_WITHDRAWN_BY_TEACHER,
           rejection_reason_label: I18n.t(
             "registration.user_registration.reason_labels.withdrawn_by_teacher"
           ))
    create(:exam_roster_entry,
           exam: exam,
           user: excluded_user,
           excluded_at: Time.current)

    render_inline(described_class.new(exam: exam))
    document = Nokogiri::HTML.fragment(rendered_content)
    add_path = Rails.application.routes.url_helpers.participants_exam_path(exam)

    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.post_finalization_hint")
    )
    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.not_on_roster_heading")
    )
    expect(rendered_content).to include(
      I18n.t("registration.user_registration.reason")
    )
    expect(rendered_content).to include(I18n.t("basics.actions"))
    expect(rendered_content).to include(
      I18n.t("registration.user_registration.reason_labels.withdrawn_by_teacher")
    )
    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.removed_from_roster_reason")
    )
    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.add_to_participants_button")
    )
    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.add_to_participants_confirm")
    )
    expect(rendered_content).to include(rejected_user.email)
    expect(rendered_content).to include(excluded_user.email)
    expect(
      document.at_css(
        "form[action='#{add_path}'] input[name='user_id'][value='#{rejected_user.id}']"
      )
    ).to be_present
    expect(
      document.at_css(
        "form[action='#{add_path}'] input[name='user_id'][value='#{excluded_user.id}']"
      )
    ).to be_present
    expect(
      document.at_css(
        "form[action='#{add_path}'][data-turbo-confirm='#{I18n.t("assessment.registration_tab.add_to_participants_confirm")}']"
      )
    ).to be_present
  end

  it "renders a detailed exam-eligibility reason after finalization" do
    exam = create(:exam, :with_date, lecture: lecture)
    campaign = exam.registration_campaign
    campaign.update!(status: :completed)
    rejected_user = create(:confirmed_user)
    create(:registration_user_registration,
           :rejected,
           registration_campaign: campaign,
           registration_item: campaign.registration_items.first,
           user: rejected_user,
           rejection_reason_type: Registration::UserRegistration::REJECTION_REASON_TYPE_POLICY,
           rejection_reason_code: "certification_not_passed",
           rejection_reason_label: I18n.t(
             "registration.policy.errors.certification_not_passed"
           ))

    render_inline(described_class.new(exam: exam))

    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.certification_not_passed_reason")
    )
    expect(rendered_content).not_to include(
      "#{I18n.t("registration.policy.errors.certification_not_passed")}."
    )
  end

  it "renders the participants removal action with explicit label after finalization" do
    exam = create(:exam, :with_date, lecture: lecture)
    exam.registration_campaign.update!(status: :completed)
    create(:exam_roster_entry, exam: exam, user: create(:confirmed_user))

    render_inline(described_class.new(exam: exam))

    document = Nokogiri::HTML.fragment(rendered_content)
    remove_action = document.at_css("button[title]")
    filter_label = document.at_css('label[for="exam-participants-filter"]')
    add_toggle = document.at_css(
      "button[data-bs-toggle='collapse'][aria-controls='exam-#{exam.id}-participants-add-form']"
    )
    add_form = document.at_css("#exam-#{exam.id}-participants-add-form.collapse")
    add_form_label = document.css(".small.fw-semibold").find do |node|
      node.text.include?(I18n.t("assessment.registration_tab.add_form_label"))
    end
    filter_label_index = rendered_content.index(
      I18n.t("assessment.registration_tab.filter_label")
    )
    add_form_label_index = rendered_content.index(
      I18n.t("assessment.registration_tab.add_form_label")
    )

    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.remove_button")
    )
    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.filter_label")
    )
    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.add_form_label")
    )
    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.add_form_hint")
    )
    expect(filter_label).to be_present
    expect(add_toggle).to be_present
    expect(add_toggle["aria-expanded"]).to eq("false")
    expect(add_form).to be_present
    expect(add_form["class"]).not_to include("show")
    expect(add_form_label).to be_present
    expect(filter_label_index).to be < add_form_label_index
    expect(remove_action["title"]).to eq(
      I18n.t("assessment.registration_tab.remove_tooltip")
    )
  end

  it "renders the add-by-email form expanded when no participants exist" do
    exam = create(:exam, :with_date, lecture: lecture)
    exam.registration_campaign.update!(status: :completed)

    render_inline(described_class.new(exam: exam))

    document = Nokogiri::HTML.fragment(rendered_content)
    add_toggle = document.at_css(
      "button[data-bs-toggle='collapse'][aria-controls='exam-#{exam.id}-participants-add-form']"
    )
    add_form = document.at_css("#exam-#{exam.id}-participants-add-form.collapse.show")

    expect(add_toggle).to be_present
    expect(add_toggle["aria-expanded"]).to eq("true")
    expect(add_form).to be_present
    expect(rendered_content).not_to include(
      I18n.t("assessment.registration_tab.filter_label")
    )
  end

  it "renders a disabled removal action when grading data exists" do
    exam = create(:exam, :with_date, lecture: lecture)
    exam.registration_campaign.update!(status: :completed)
    user = create(:confirmed_user)
    create(:exam_roster_entry, exam: exam, user: user)
    assessment = create(:assessment, :with_points, assessable: exam,
                                                   lecture: lecture)
    task = create(:assessment_task, assessment: assessment)
    participation = create(:assessment_participation,
                           assessment: assessment,
                           user: user,
                           status: :pending,
                           submitted_at: nil)
    create(:assessment_task_point,
           task: task,
           assessment_participation: participation)

    render_inline(described_class.new(exam: exam))

    document = Nokogiri::HTML.fragment(rendered_content)
    disabled_wrapper = document.at_css(
      "span[title='#{I18n.t("assessment.registration_tab.remove_disabled_tooltip")}']"
    )
    disabled_button = document.at_css(
      "button[disabled][aria-label='#{I18n.t("assessment.registration_tab.remove_disabled_tooltip")}']"
    )
    remove_path = Rails.application.routes.url_helpers.remove_participant_exam_path(
      exam,
      user_id: user.id
    )

    expect(disabled_wrapper).to be_present
    expect(disabled_button).to be_present
    expect(rendered_content).not_to include(remove_path)
  end

  it "renders retry-reopen mode without the header reopen button" do
    exam = create(:exam, :with_date, lecture: lecture)
    exam.registration_campaign.update!(status: :closed)
    exam.reopen_after_deadline_fix = true
    exam.registration_deadline = 1.day.ago.strftime("%Y-%m-%d %H:%M")
    exam.errors.add(:registration_deadline, :must_be_in_future)

    render_inline(described_class.new(exam: exam))

    document = Nokogiri::HTML.fragment(rendered_content)
    header_reopen = document.at_css("form.button_to[action$='/reopen'] button")
    retry_submit = document.at_css(
      "input[data-exams--registration-settings-target='submitButton']"
    )

    expect(header_reopen).to be_nil
    expect(retry_submit).to be_present
    expect(retry_submit["value"]).to eq(
      I18n.t("registration.campaign.actions.reopen")
    )
  end
end
