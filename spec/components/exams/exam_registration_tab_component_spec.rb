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
