require "rails_helper"

RSpec.describe(ExamSettingsComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }

  before do
    Flipper.enable(:registration_campaigns)
  end

  after do
    Flipper.disable(:registration_campaigns)
  end

  context "with an existing exam" do
    let(:exam) do
      create(:exam, :with_capacity, :with_date,
             lecture: lecture, location: "Room 101")
    end

    it "renders the opening hint for a draft campaign" do
      render_inline(described_class.new(exam: exam))
      document = Nokogiri::HTML.fragment(rendered_content)

      expect(document.text).to include(
        I18n.t("assessment.settings_tab.registration_hint.inline")
      )
      expect(rendered_content).to include("bg-warning-subtle")
    end

    it "renders registered count info for an open campaign" do
      exam.registration_campaign.update!(status: :open)

      render_inline(described_class.new(exam: exam))

      expect(rendered_content).to include(
        I18n.t("assessment.info_bar.registered")
      )
      expect(rendered_content).to include("bg-info-subtle")
    end
  end

  context "with a new exam" do
    let(:exam) { build(:exam, lecture: lecture) }

    it "renders the back button and heading" do
      render_inline(described_class.new(exam: exam))

      expect(rendered_content).to include(I18n.t("back"))
      expect(rendered_content).to include(I18n.t("assessment.new_exam"))
    end
  end
end
