class ExamPointingTableComponent < ViewComponent::Base
  def initialize(exam:)
    super()
    @exam = exam
    @lecture = exam.lecture
    @assessment = exam.assessment
    @config = Assessment::DisplayConfigResolver.resolve(
      assessable: @exam, grading_scope: @grading_scope, table_option: :pointing
    )
    @participations = participations_index.values
  end

  def grading_enabled?
    @exam.assessable?
  end

  def tasks
    @exam&.assessment&.persisted_tasks || []
  end

  def total_max_points
    @exam&.assessment&.effective_total_points || 0
  end

  def grading_records?
    @participations.any?
  end

  def column_count
    4 + tasks.count
  end

  LINK_STYLE = "display:inline-flex; align-items:center; gap:4px; " \
               "padding:4px 10px; border-radius:6px; " \
               "border:1px solid #e0e0e0; background:#fff; " \
               "font-size:12px; color:#555; text-decoration:none;".freeze

  def mark_as_exempt_link(participation)
    path = mark_user_as_exempt_path(participation)

    link_to(path,
            style: LINK_STYLE,
            data: { turbo_method: :patch,
                    turbo_confirm: t("assessment.grading_tutorial.confirm_unsaved_changes") }) do
      safe_join([
                  content_tag(:span, "check", class: "material-icons", style: "font-size: 14px;"),
                  t("assessment.grading_tutorial.mark_as_exempt")
                ])
    end
  end

  def mark_as_absent_link(participation)
    path = mark_user_as_absent_path(participation)

    link_to(path,
            style: LINK_STYLE,
            data: { turbo_method: :patch,
                    turbo_confirm: t("assessment.grading_tutorial.confirm_unsaved_changes") }) do
      safe_join([
                  content_tag(:span, "check", class: "material-icons", style: "font-size: 14px;"),
                  t("assessment.grading_tutorial.mark_as_absent")
                ])
    end
  end

  def sticky_layout
    @sticky_layout ||= Assessment::StickyColumnLayout.new(
      left_columns: @config.left_columns,
      right_columns: @config.right_columns
    )
  end

  def sticky_css_vars
    return unless @config

    helpers.sticky_css_vars_calc(sticky_layout)
  end

  private

    def participations_index
      @participations_index ||= Assessment::ExamGraderService.init_participations(
        @exam.roster_entries.map do |exam_roster_entry|
          [exam_roster_entry.exam.assessment, exam_roster_entry.user]
        end
      )
    end

    def exam_users
      @exam.lecture.students
    end
end
