# The exam's points tab: one row per candidate on the roster, points per
# task. The grade for the same rows lives in the grading tab.
class ExamPointingTableComponent < ViewComponent::Base
  def initialize(exam:)
    super()
    @exam = exam
    @lecture = exam.lecture
    @assessment = exam.assessment
  end

  delegate :status_options, to: :ExamRows

  def layout
    @layout ||= PointingTableLayout.for(assessable: @exam, table_option: :pointing)
  end

  def rows
    @rows ||= ExamRows.for(@exam)
  end

  def row_for(participation)
    ParticipationRowComponent.new(participation: participation, assessment: @assessment,
                                  grading_scope: @lecture, table_option: :pointing)
  end

  def row_statuses
    rows.map(&:display_status)
  end

  def summary
    PointingSummaryComponent.new(statuses: row_statuses, hand_ins: false)
  end
end
