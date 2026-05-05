class ExamCampaignUiState
  ACTIVE_CAMPAIGN_STATUSES = [:draft, :open, :closed, :processing].freeze

  def initialize(exam:, registration_campaigns_enabled: Flipper.enabled?(:registration_campaigns))
    @exam = exam
    @registration_campaigns_enabled = registration_campaigns_enabled
  end

  attr_reader :exam

  def campaign
    @campaign ||= exam.registration_campaign
  end

  def registration_tab_label
    I18n.t(registration_tab_label_key)
  end

  def registration_tab_needs_attention?
    !exam.skip_campaigns && !exam.new_record? && (campaign.nil? || campaign.draft?)
  end

  def registration_tab_tooltip
    I18n.t("assessment.registration_tab.needs_attention_tooltip")
  end

  def settings_needs_opening?
    !exam.skip_campaigns && registration_campaigns_enabled? &&
      (campaign.nil? || campaign.draft?)
  end

  def info_bar_background_class
    settings_needs_opening? ? "bg-warning-subtle" : "bg-info-subtle"
  end

  private

    def registration_tab_label_key
      if exam.skip_campaigns || campaign&.completed?
        "assessment.roster"
      else
        "assessment.registrations_label"
      end
    end

    def registration_campaigns_enabled?
      @registration_campaigns_enabled
    end
end