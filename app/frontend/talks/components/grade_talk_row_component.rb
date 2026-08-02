class GradeTalkRowComponent < ViewComponent::Base
  def initialize(user:, talk:, participation: nil)
    super()
    @user = user
    @talk = talk
    @participation = participation || user.assessment_participation_in_assessable(talk)
  end

  def grading_enabled?
    Flipper.enabled?(:assessment_grading)
  end

  def allow_grading?
    grading_enabled? && can_grade? && !locked?
  end

  def locked?
    @participation&.locked? || false
  end

  def row_id
    "participation-row-user-#{@user.id}"
  end

  def status_label
    return I18n.t("assessment.grade_talk_row.pending") unless @participation

    I18n.t("assessment.grade_talk_row.#{@participation.status}")
  end

  def status_value
    @participation&.status || :pending
  end

  def grade_text
    @participation&.grade_text
  end

  def grade_display
    return "—" if grade_text.blank?

    I18n.t("assessment.grades.#{grade_text}", default: grade_text)
  end

  def grade_options
    Assessment::GradeEntryService::VALID_GRADES_NUMERIC.map do |g|
      [I18n.t("assessment.grades.#{g}", default: g), g]
    end
  end

  def grade_select_input
    tag.select(
      name: "grade",
      class: "form-select form-select-sm",
      disabled: !allow_grading?
    ) do
      safe_join(
        grade_options.map do |label, value|
          tag.option(label, value: value, selected: value == grade_text)
        end
      )
    end
  end

  def note_input
    tag.input(
      type: "text",
      autocomplete: "off",
      name: "comment",
      value: @participation&.note,
      class: "form-control form-control-sm",
      disabled: !allow_grading?
    )
  end

  def grader_display
    @participation&.grader&.tutorial_name
  end

  def graded_at_relative
    return nil unless @participation&.graded_at

    helpers.time_ago_in_words(@participation.graded_at)
  end

  def graded_at_full
    return nil unless @participation&.graded_at

    I18n.l(@participation.graded_at, format: :short)
  end

  def badge_status_participation_color
    {
      pending: "warning",
      reviewed: "success",
      exempt: "info",
      absent: "info"
    }[status_value&.to_sym]
  end

  def badge_status_participation_class
    "badge rounded-pill bg-#{badge_status_participation_color}"
  end

  # Since there may be no participation yet, submit against user+talk;
  # controller should find_or_create_by(user:, talk:) on first save.
  def grade_form_url
    helpers.grade_talk_user_path(@talk, @user)
  end

  def refresh_form_url
    helpers.refresh_grade_talk_user_path(@talk, @user)
  end

  def mark_absent_url
    helpers.mark_absent_talk_user_path(@talk, @user)
  end

  def save_row_button
    class_name = "btn btn-sm btn-success d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1"
    tag.button(type: "button",
               class: class_name,
               data: { action: "click->grade-talk-row#saveRow", grade_talk_row_target: "save" },
               title: helpers.t("buttons.save"),
               disabled: !allow_grading?) do
      tag.i(class: "bi bi-save")
    end
  end

  def refresh_row_button
    class_name = "btn btn-sm btn-outline-secondary d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1"
    tag.button(type: "button",
               class: class_name,
               data: { bs_toggle: "tooltip", action: "click->grade-talk-row#refreshRow" },
               title: helpers.t("buttons.refresh"),
               disabled: !allow_grading?) do
      tag.i(class: "bi bi-arrow-clockwise")
    end
  end

  def can_grade?
    user = helpers.current_user
    user.admin? || user.can_grade_in_scope?(@talk.lecture)
  end
end
