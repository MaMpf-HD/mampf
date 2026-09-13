class ExamPointingTableComponent < ViewComponent::Base
  def initialize(exam:)
    super()
    @exam = exam
    @lecture = exam.lecture
    @assessment = exam.assessment
    @participations = participations_index.values
  end

  def layout
    @layout ||= PointingTableLayout.for(assessable: @exam, grading_scope: @grading_scope,
                                        table_option: :pointing)
  end

  def toolbar
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

  def summary
    PointingSummaryComponent.new(statuses: row_statuses)
  end

  def row_statuses
    @participations.map(&:display_status)
  end

  private

    def participations_index
      @participations_index ||= Assessment::ExamGraderService.init_participations(
        @exam.roster_entries.map do |exam_roster_entry|
          [exam_roster_entry.exam.assessment, exam_roster_entry.user]
        end
      )
    end
end
