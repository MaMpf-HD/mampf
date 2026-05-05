class ExamRegistrationTabComponent < ViewComponent::Base
  def initialize(exam:)
    super()
    @exam = exam
  end

  attr_reader :exam

  def campaign
    @campaign ||= exam.registration_campaign
  end

  def frame_id
    @frame_id ||= "exam_#{exam.id}_registration"
  end

  def button_params
    @button_params ||= { frame_id: frame_id }
  end

  def allocation_workspace_id
    @allocation_workspace_id ||= Registration::Campaign.exam_workspace_frame_id(exam)
  end

  def deadline_editable?
    exam.reopen_after_deadline_fix || campaign&.draft? || campaign&.open?
  end

  def show_deadline_form?
    campaign.present? && !campaign.completed?
  end

  def show_allocation_workspace?
    campaign&.closed? || campaign&.processing?
  end

  def show_registrants_table?
    campaign&.open? || campaign&.closed?
  end

  def show_post_finalization?
    campaign.present? && !show_registrants_table? && !pre_finalization?
  end

  def participants_entries
    @participants_entries ||= exam.exam_roster_entries
                                  .includes(:user)
                                  .joins(:user)
                                  .merge(User.order(:name))
  end

  def excluded_participants_entries
    @excluded_participants_entries ||= exam.excluded_exam_roster_entries
                                           .includes(:user)
                                           .joins(:user)
                                           .merge(User.order(:name))
  end

  def registration_header_locals
    {
      campaign: campaign,
      bp: button_params,
      allocation_workspace_id: allocation_workspace_id,
      show_draft_badge: campaign.draft?,
      show_registration_status_badge: !campaign.draft? && !campaign.completed?,
      finalized_on: campaign.completed? ? campaign.updated_at : nil,
      registered_count: registered_count,
      show_open_action: campaign.draft?,
      show_close_action: campaign.open?,
      show_reopen_action: campaign.closed? && !exam.reopen_after_deadline_fix,
      show_review_and_finalize_action: campaign.closed? || campaign.processing?
    }
  end

  def deadline_form_locals
    {
      exam: exam,
      deadline_editable: deadline_editable?,
      deadline_value: deadline_value,
      form_data: deadline_form_data,
      input_data: deadline_input_data,
      submit_label: deadline_submit_label,
      picker_role: deadline_picker_role,
      picker_target: deadline_picker_target,
      picker_toggle: deadline_picker_toggle,
      picker_button_classes: deadline_picker_button_classes,
      show_warning_actions: deadline_editable?
    }
  end

  def rejected_registrations
    return Registration::UserRegistration.none unless campaign

    @rejected_registrations ||= campaign.user_registrations
                                        .where(status: :rejected)
                                        .includes(:user)
                                        .joins(:user)
                                        .merge(User.order(:name))
  end

  def not_on_roster_entries
    @not_on_roster_entries ||= begin
      participant_user_ids = participants_entries.map(&:user_id)
      entries_by_user_id = {}

      rejected_registrations.each do |registration|
        next if participant_user_ids.include?(registration.user_id)

        entries_by_user_id[registration.user_id] = {
          user: registration.user,
          reason_label: post_finalization_reason_label(registration)
        }
      end

      excluded_participants_entries.each do |roster_entry|
        entries_by_user_id[roster_entry.user_id] = {
          user: roster_entry.user,
          reason_label: roster_entry.exclusion_reason_label
        }
      end

      entries_by_user_id.values.sort_by do |entry|
        [entry[:user].name.to_s, entry[:user].email.to_s]
      end
    end
  end

  private

    def post_finalization_reason_label(registration)
      if registration.rejection_reason_code == "certification_not_passed"
        return helpers.t("assessment.registration_tab.certification_not_passed_reason")
      end

      registration.localized_rejection_reason_label
    end

    def pre_finalization?
      exam.status_phase.in?([:draft, :registration_open, :registration_closed])
    end

    def registered_count
      return unless campaign.open? || campaign.closed? || campaign.processing?

      campaign.total_registrations_count
    end

    def deadline_value
      exam.registration_deadline || campaign&.registration_deadline
    end

    def deadline_form_data
      data = { turbo: true }
      return data unless deadline_editable?

      data.merge(
        controller: "exams--registration-settings",
        action: "turbo:submit-end->exams--registration-settings#resetAfterSave"
      )
    end

    def deadline_input_data
      data = { td_target: "#exam-settings-deadline-picker" }
      return data unless deadline_editable?

      data.merge(
        exams__registration_settings_target: "registrationDeadline",
        action: "change->exams--registration-settings#checkForChanges " \
                "input->exams--registration-settings#checkForChanges"
      )
    end

    def deadline_submit_label
      if exam.reopen_after_deadline_fix
        helpers.t("registration.campaign.actions.reopen")
      else
        helpers.t("buttons.save")
      end
    end

    def deadline_picker_role
      deadline_editable? ? "button" : nil
    end

    def deadline_picker_target
      deadline_editable? ? "#exam-settings-deadline-picker" : nil
    end

    def deadline_picker_toggle
      deadline_editable? ? "datetimepicker" : nil
    end

    def deadline_picker_button_classes
      helpers.class_names(
        "input-group-text td-picker-button",
        "disabled opacity-50": !deadline_editable?
      )
    end
end