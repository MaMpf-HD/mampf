require "rails_helper"

RSpec.describe(ExamCampaignUiState) do
  let(:exam) { FactoryBot.create(:exam, :written) }

  def label_for(campaign_status)
    campaign = exam.registration_campaign
    # rubocop:disable Rails/SkipsModelValidations
    campaign.update_column(:status,
                           Registration::Campaign.statuses[campaign_status])
    # rubocop:enable Rails/SkipsModelValidations
    described_class.new(exam: exam).status_label
  end

  describe "#status_label" do
    # The badge sits on an exam, so it has to say what is open about the exam.
    # "Open" is right on a campaign card and says nothing here.
    it "reads the campaign in the language of the exam" do
      expect(label_for(:open))
        .to eq(I18n.t("assessment.exam_status.registration_open"))
      expect(label_for(:open))
        .not_to eq(I18n.t("registration.campaign.status.open"))
    end

    it "has a word of its own for a campaign being processed" do
      expect(label_for(:processing))
        .to eq(I18n.t("assessment.exam_status.registration_processing"))
    end

    it "keeps speaking the exam's phase once the campaign is over" do
      expect(label_for(:completed))
        .to eq(I18n.t("assessment.exam_status.#{exam.status_phase}"))
    end
  end
end
