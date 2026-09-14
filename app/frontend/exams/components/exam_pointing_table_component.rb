# The exam's points tab: one row per candidate on the roster, points per
# task. The grade for the same rows lives in the grading tab.
class ExamPointingTableComponent < ViewComponent::Base
  # `rows:` lets an answer that redraws both tables load the roster once.
  def initialize(exam:, rows: nil)
    super()
    @exam = exam
    @lecture = exam.lecture
    @assessment = exam.assessment
    @rows = rows
  end

  delegate :status_options, to: :ExamRows

  def tutorial_options
    ExamRows.tutorial_options(@exam)
  end

  def layout
    @layout ||= PointingTableLayout.for(assessable: @exam, table_option: :pointing)
  end

  def rows
    @rows ||= ExamRows.for(@exam)
  end

  def row_for(participation)
    ParticipationRowComponent.new(participation: participation, assessment: @assessment,
                                  grading_scope: @lecture, table_option: :pointing,
                                  filter_tutorial_id: tutorial_ids_by_user[participation.user_id])
  end

  def row_statuses
    rows.map(&:display_status)
  end

  def summary
    PointingSummaryComponent.new(statuses: row_statuses, hand_ins: false)
  end

  private

    def tutorial_ids_by_user
      @tutorial_ids_by_user ||= ExamRows.tutorial_ids_by_user(@exam)
    end
end
