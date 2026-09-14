# The exam's grading tab: the same candidates as the points tab, with the
# grade the scheme proposes beside the one the lecturer enters.
class ExamGradingTableComponent < ViewComponent::Base
  def initialize(exam:)
    super()
    @exam = exam
    @lecture = exam.lecture
    @assessment = exam.assessment
  end

  def layout
    @layout ||= PointingTableLayout.for(assessable: @exam, table_option: :grading)
  end

  def rows
    @rows ||= ExamRows.for(@exam)
  end

  def row_for(participation)
    ParticipationRowComponent.new(participation: participation, assessment: @assessment,
                                  grading_scope: @lecture, table_option: :grading,
                                  proposal: proposal_for(participation),
                                  filter_tutorial_id: tutorial_ids_by_user[participation.user_id])
  end

  def row_statuses
    rows.map(&:display_status)
  end

  # Points corrected after grading are the summary's business too: a row
  # in that state needs a look, whatever its status says.
  def summary
    extra = []
    if points_changed_count.positive?
      extra << I18n.t("assessment.grading_exam.summary_points_changed",
                      count: points_changed_count)
    end
    PointingSummaryComponent.new(statuses: row_statuses, hand_ins: false, id: "grading-summary",
                                 extra_parts: extra)
  end

  def points_changed_count
    @points_changed_count ||= rows.count(&:points_changed_after_grading?)
  end

  def points_changed_alert
    PointsChangedAlertComponent.new(count: points_changed_count)
  end

  # The filter's states, plus the spot a graded row can be in.
  def status_options
    ExamRows.status_options +
      [["flag:points_changed", I18n.t("assessment.grading_exam.filter_points_changed")]]
  end

  def tutorial_options
    ExamRows.tutorial_options(@exam)
  end

  private

    def tutorial_ids_by_user
      @tutorial_ids_by_user ||= ExamRows.tutorial_ids_by_user(@exam)
    end

    # The active scheme's answer for today's points stands beside the grade:
    # as a proposal while the scheme is unapplied, as a discrepancy once it
    # is - nothing recomputes an applied grade when points change.
    def scheme
      candidate = @assessment.grade_scheme
      candidate if candidate&.persisted?
    end

    def proposal_tooltip
      return unless scheme

      key = scheme.applied? ? "grading_exam.scheme_now_gives" : "grade_table.proposed_tooltip"
      I18n.t("assessment.#{key}")
    end

    def proposal_for(participation)
      grade = proposed_grades[participation.user_id]
      ParticipationRowComponent::Proposal.new(grade: grade, tooltip: proposal_tooltip) if grade
    end

    def proposed_grades
      return {} unless scheme

      @proposed_grades ||= Assessment::GradeSchemeApplier.new(scheme).proposed_grade_map
    end
end
