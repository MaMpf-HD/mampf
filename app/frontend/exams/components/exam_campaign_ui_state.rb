class ExamCampaignUiState
  ACTIVE_CAMPAIGN_STATUSES = [:draft, :open, :closed, :processing].freeze

  # While the campaign is running its own status drives the badge; afterwards
  # the exam's phase does.
  CAMPAIGN_BADGE_CLASSES = {
    draft: "bg-secondary",
    open: "bg-success",
    closed: "bg-warning",
    processing: "bg-info"
  }.freeze

  STATUS_PHASE_BADGE_CLASSES = {
    draft: "bg-secondary",
    registration_open: "bg-primary",
    registration_closed: "bg-info",
    finalized: "bg-danger",
    conducted: "bg-light text-dark border",
    grading: "bg-white text-primary border border-primary",
    graded: "bg-primary"
  }.freeze

  def initialize(exam:)
    @exam = exam
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
    !exam.skip_campaigns && (campaign.nil? || campaign.draft?)
  end

  def info_bar_background_class
    settings_needs_opening? ? "bg-warning-subtle" : "bg-info-subtle"
  end

  def status_badge_class
    if active_campaign_status?
      CAMPAIGN_BADGE_CLASSES.fetch(campaign.status.to_sym)
    else
      STATUS_PHASE_BADGE_CLASSES.fetch(exam.status_phase)
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
end
