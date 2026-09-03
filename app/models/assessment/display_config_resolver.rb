module Assessment
  GradingDisplayConfig = Struct.new(
    :body_mode,
    :mode,
    :left_columns,
    :right_columns,
    :stimulus_controller,
    keyword_init: true
  )

  class DisplayConfigResolver
    class UnsupportedCombinationError < StandardError; end

    def self.resolve(assessable:, grading_scope:)
      case assessable
      when Assignment
        resolve_assignment(grading_scope)
      when Talk
        resolve_talk(grading_scope)
      else
        raise(UnsupportedCombinationError,
              "No display config for #{assessable.class} / #{grading_scope.class}")
      end
    end

    def self.resolve_assignment(grading_scope)
      tutor = grading_scope.is_a?(Tutorial)

      GradingDisplayConfig.new(
        body_mode: :tasks,
        mode: tutor ? "tutor" : "teacher",
        left_columns: tutor ? [:team, :status] : [:team, :tutorial, :status],
        right_columns: tutor ? [:total, :action, :correction] : [:total, :action],
        stimulus_controller: "participation-row"
      )
    end
    private_class_method :resolve_assignment

    def self.resolve_talk(_grading_scope)
      GradingDisplayConfig.new(
        body_mode: :single_grade,
        mode: "talk",
        left_columns: [:team, :status],
        right_columns: [:grade, :note, :graded_at, :graded_by, :note, :action],
        stimulus_controller: "grade-talk-row"
      )
    end
    private_class_method :resolve_talk
  end
end
