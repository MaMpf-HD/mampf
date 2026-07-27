# Renders a single participation row in the talk grading table
class GradeTalkRowComponent < ViewComponent::Base
  class MissingUserError < StandardError; end

  def initialize(participation:, talk:)
    super()
    @participation = participation
    @talk = talk
    @user ||= @participation&.user
  end

  def grading_enabled?
    Flipper.enabled?(:assessment_grading)
  end

  def allow_grading?
    grading_enabled? && can_grade? && !@participation.locked?
  end

  def row_id
    "participation-row-#{@participation.id}"
  end

  def status_label(participation)
    I18n.t("assessment.grade_talk_row.#{participation.status}")
  end

  def grade_display(participation)
    return "—" if participation.grade_text.blank?

    I18n.t("assessment.grades.#{participation.grade_text}",
           default: participation.grade_text)
  end

  def grade_options
    Assessment::GradeEntryService::VALID_TALK_GRADES.map do |g|
      [I18n.t("assessment.grades.#{g}", default: g), g]
    end
  end

  def grade_select_input(participation, allow_grading)
    tag.select(
      name: "grade",
      data: {
        grade_row_target: "grade",
        action: "change->grade-row#onGradeChanged"
      },
      class: "form-select form-select-sm",
      disabled: !allow_grading
    ) do
      safe_join(
        grade_options.map do |label, value|
          tag.option(label, value: value, selected: value == participation.grade_text)
        end
      )
    end
  end

  def note_input(participation, allow_grading)
    tag.input(
      type: "text",
      autocomplete: "off",
      name: "comment",
      value: participation.note,
      data: {
        grade_row_target: "note",
        action: "input->grade-row#onNoteChanged"
      },
      class: "form-control form-control-sm",
      disabled: !allow_grading
    )
  end

  def grader_display(participation)
    participation.grader&.tutorial_name
  end

  def graded_at_relative(participation)
    return nil unless participation.graded_at

    helpers.time_ago_in_words(participation.graded_at)
  end

  def graded_at_full(participation)
    return nil unless participation.graded_at

    I18n.l(participation.graded_at, format: :short)
  end

  def badge_status_participation_color(status)
    {
      pending: "warning",
      reviewed: "success",
      exempt: "info",
      absent: "info"
    }[status&.to_sym]
  end

  def badge_status_participation_class(status)
    "badge rounded-pill bg-#{badge_status_participation_color(status)}"
  end

  def save_row_button(allow_grading)
    class_name = "btn btn-sm btn-success d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1"
    tag.button(type: "button",
               class: class_name,
               data: { bs_toggle: "tooltip",
                       grade_row_target: "save",
                       action: "click->grade-row#saveRow" },
               title: helpers.t("buttons.save"),
               disabled: !allow_grading) do
      tag.i(class: "bi bi-save")
    end
  end

  def refresh_row_button(allow_grading)
    class_name = "btn btn-sm btn-outline-secondary d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1"
    tag.button(type: "button",
               class: class_name,
               data: { bs_toggle: "tooltip", action: "click->grade-row#refreshRow" },
               title: helpers.t("buttons.refresh"),
               disabled: !allow_grading) do
      tag.i(class: "bi bi-arrow-clockwise")
    end
  end

  def mark_absent_button(allow_grading)
    class_name = "btn btn-sm btn-outline-danger d-inline-flex align-items-center " \
                 "justify-content-center text-nowrap px-2 py-1 lh-1"
    tag.button(type: "button",
               class: class_name,
               data: { bs_toggle: "tooltip", action: "click->grade-row#markAbsent" },
               title: helpers.t("assessment.mark_absent"),
               disabled: !allow_grading) do
      tag.i(class: "bi bi-person-x")
    end
  end

  def can_grade?
    user = helpers.current_user
    user.admin? || user.can_grade_in_scope?(@lecture)
  end
end
