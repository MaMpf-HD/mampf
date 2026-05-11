class ExamSettingsComponent < ViewComponent::Base
  def initialize(exam:)
    super()
    @exam = exam
  end

  attr_reader :exam

  def campaign
    campaign_ui_state.campaign if registration_campaigns_enabled?
  end

  def show_info_bar?
    !exam.new_record?
  end

  def needs_opening?
    campaign_ui_state.settings_needs_opening?
  end

  delegate :info_bar_background_class, to: :campaign_ui_state

  def participant_count
    registration_active? ? campaign.total_registrations_count : exam.roster_entries_count
  end

  def participant_count_label
    if registration_active?
      helpers.t("assessment.info_bar.registered")
    else
      helpers.t("assessment.info_bar.participants")
    end
  end

  def display_date
    exam.date ? helpers.l(exam.date, format: :long) : helpers.t("basics.not_specified")
  end

  def display_location
    exam.location.presence || helpers.t("basics.not_specified")
  end

  def show_back_button?
    exam.new_record?
  end

  def show_delete_button?
    !exam.new_record?
  end

  def form_url
    if exam.new_record?
      helpers.exams_path
    else
      helpers.exam_path(exam, tab: "settings")
    end
  end

  def back_path
    helpers.exams_path(lecture_id: exam.lecture_id)
  end

  private

    def campaign_ui_state
      @campaign_ui_state ||= ExamCampaignUiState.new(exam: exam)
    end

    def registration_campaigns_enabled?
      Flipper.enabled?(:registration_campaigns)
    end

    def registration_active?
      campaign && !campaign.completed?
    end
end
