class ExamPointingTableComponent < ViewComponent::Base
  def initialize(exam:, draft_scheme: nil)
    super()
    @exam = exam
    @lecture = exam.lecture
    @assessment = exam.assessment
    @config = Assessment::DisplayConfigResolver.resolve(
      assessable: @exam, grading_scope: @grading_scope, table_option: :pointing
    )
    @participations = participations_index.values
    @draft_scheme = draft_scheme
  end

  def grading_enabled?
    @exam.assessable?
  end

  def draft_scheme?
    draft_scheme.present?
  end

  def proposed_grade_map
    @proposed_grade_map ||= if draft_scheme?
      Assessment::GradeSchemeApplier.new(draft_scheme).proposed_grade_map
    else
      {}
    end
  end

  def proposed_grade_for(participation)
    proposed_grade_map[participation.user_id]
  end

  def grade_changed?(participation)
    return false unless draft_scheme?

    proposed = proposed_grade_for(participation)
    return false if proposed.nil?

    participation.grade_numeric != proposed
  end

  def format_grade(value)
    return nil if value.nil?

    value.to_s
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
