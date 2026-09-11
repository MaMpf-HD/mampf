module Assessment
  GradingDisplayConfig = Struct.new(
    :body_mode,
    :mode,
    :left_columns,
    :right_columns,
    keyword_init: true
  )

  TABLE_OPTIONS = {
    pointing: 0,
    grading: 1
  }.freeze

  class DisplayConfigResolver
    class UnsupportedCombinationError < StandardError; end

    def self.resolve(assessable:, grading_scope:, table_option: nil)
      case assessable
      when Assignment
        resolve_assignment(grading_scope)
      when Talk
        resolve_talk(grading_scope)
      when Exam
        case table_option
        when :pointing
          resolve_exam_pointing(grading_scope)
        when :grading
          resolve_exam_grading(grading_scope)
        end
      else
        raise(UnsupportedCombinationError,
              "No display config for #{assessable.class} / #{grading_scope.class}")
      end
    end

    def self.resolve_assignment(grading_scope)
      tutor = grading_scope.is_a?(Tutorial)

      GradingDisplayConfig.new(
        body_mode: [:tasks],
        left_columns: tutor ? [:team, :status] : [:team, :tutorial, :status],
        right_columns: tutor ? [:total, :action, :correction] : [:total, :action]
      )
    end
    private_class_method :resolve_assignment

    def self.resolve_talk(_grading_scope)
      GradingDisplayConfig.new(
        body_mode: [:single_grade],
        left_columns: [:team, :status],
        right_columns: [:grade, :note, :graded_by, :graded_at, :action]
      )
    end
    private_class_method :resolve_talk

    def self.resolve_exam_pointing(_grading_scope)
      GradingDisplayConfig.new(
        body_mode: [:tasks],
        left_columns: [:team, :status],
        right_columns: [:total, :action]
      )
    end
    private_class_method :resolve_exam_pointing

    def self.resolve_exam_grading(_grading_scope)
      GradingDisplayConfig.new(
        body_mode: [:single_grade],
        left_columns: [:team, :status],
        right_columns: [:grade, :note, :graded_by, :graded_at, :action]
      )
    end
    private_class_method :resolve_exam_grading
  end
end
