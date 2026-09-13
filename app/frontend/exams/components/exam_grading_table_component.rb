class ExamGradingTableComponent < ViewComponent::Base
  def initialize(exam:, draft_scheme: nil)
    super()
    @exam = exam
    @draft_scheme = draft_scheme
    @lecture = exam.lecture
    @assessment = exam.assessment
    @participations = participations_index.values
  end

  def layout
    @layout ||= PointingTableLayout.for(assessable: @exam, grading_scope: @grading_scope,
                                        table_option: :grading)
  end

  def grading_enabled?
    @exam.assessable?
  end

  def possible_statuses
    ["pending", "reviewed"]
  end

  def grading_records?
    @participations.any?
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
