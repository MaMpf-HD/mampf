class ExamGradingTableComponent < ViewComponent::Base
  def initialize(exam:)
    super()
    @exam = exam
    @lecture = exam.lecture
    @assessment = exam.assessment
    @config = Assessment::DisplayConfigResolver.resolve(
      assessable: @exam, grading_scope: @grading_scope, table_option: :grading
    )
    @participations = participations_index.values
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
end
