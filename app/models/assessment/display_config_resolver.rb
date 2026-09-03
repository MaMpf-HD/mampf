module Assessment
  GradingDisplayConfig = Struct.new(
    :body_mode,
    :mode,
    :show_tutorial_col,
    :show_correction_col,
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
        show_tutorial_col: !tutor,
        show_correction_col: tutor
      )
    end
    private_class_method :resolve_assignment

    def self.resolve_talk(_grading_scope)
      GradingDisplayConfig.new(
        body_mode: :single_grade,
        mode: nil,
        show_tutorial_col: false,
        show_correction_col: false
      )
    end
    private_class_method :resolve_talk
  end
end
