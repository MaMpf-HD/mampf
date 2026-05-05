class ExamCampaignUiState
  ACTIVE_CAMPAIGN_STATUSES = [:draft, :open, :closed, :processing].freeze

  CAMPAIGN_BADGE_CLASSES = {
    draft: "bg-secondary",
    open: "bg-success",
    closed: "bg-warning",
    processing: "bg-info"
  }.freeze

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

  def status_badge_class
    if active_campaign_status?
      CAMPAIGN_BADGE_CLASSES.fetch(campaign.status.to_sym)
    else
      Exam::STATUS_PHASE_BADGE_CLASSES.fetch(exam.status_phase)
    end
  end

  def status_label
    if active_campaign_status?
      I18n.t("registration.campaign.status.#{campaign.status}")
    else
      I18n.t("assessment.exam_status.#{exam.status_phase}")
    end
  end

  private

    def registration_tab_label_key
      if exam.skip_campaigns || campaign&.completed?
        "assessment.roster"
      else
        "assessment.registrations_label"
      end
    end

    def active_campaign_status?
      campaign&.status&.to_sym.in?(ACTIVE_CAMPAIGN_STATUSES)
    end

    def registration_campaigns_enabled?
      @registration_campaigns_enabled
    end
end
