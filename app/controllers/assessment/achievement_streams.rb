module Assessment
  # Builds the streams an achievement's row update answers with: the row,
  # the summary over the table, and the dashboard's delete button, which
  # locks with the first value and opens again with the last one cleared.
  module AchievementStreams
    private

      def achievement_summary_stream(achievement, grading_scope)
        summary = AchievementMarkingTableComponent.new(achievement: achievement,
                                                       grading_scope: grading_scope).summary
        turbo_stream.replace("marking-summary", html: render_to_string(summary))
      end

      # The tutor's page has no such button; Turbo ignores a replacement
      # without a target.
      def achievement_delete_button_stream(achievement)
        turbo_stream.replace(
          "achievement-delete-button",
          html: render_to_string(partial: "student_performance/achievements/delete_button",
                                 locals: { achievement: achievement,
                                           lecture: achievement.lecture })
        )
      end
  end
end
