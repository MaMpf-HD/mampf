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

    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.post_finalization_hint")
    )
    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.not_on_roster_heading")
    )
    expect(rendered_content).to include(
      I18n.t("registration.user_registration.reason_labels.withdrawn_by_teacher")
    )
    expect(rendered_content).to include(
      I18n.t("assessment.registration_tab.removed_from_roster_reason")
    )
    expect(rendered_content).to include(rejected_user.email)
    expect(rendered_content).to include(excluded_user.email)
  end
end