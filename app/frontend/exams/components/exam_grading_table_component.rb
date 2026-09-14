# The exam's grading tab: the same candidates as the points tab, with the
# grade the scheme proposes beside the one the lecturer enters.
class ExamGradingTableComponent < ViewComponent::Base
  delegate :status_options, to: :ExamRows

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
                                  proposed_grade: proposed_grades[participation.user_id])
  end

  def row_statuses
    rows.map(&:display_status)
  end

  def summary
    PointingSummaryComponent.new(statuses: row_statuses, hand_ins: false, id: "grading-summary")
  end

  private

    # A scheme saved but not yet applied is the one whose proposals are shown.
    def draft_scheme
      scheme = @assessment.grade_scheme
      scheme if scheme&.persisted? && !scheme.applied?
    end

    def proposed_grades
      @proposed_grades ||= if draft_scheme
        Assessment::GradeSchemeApplier.new(draft_scheme).proposed_grade_map
      else
        {}
      end
    end
end
