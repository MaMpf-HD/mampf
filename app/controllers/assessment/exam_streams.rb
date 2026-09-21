module Assessment
  # Builds row, summary, alert, and scheme card streams for exam updates.
  module ExamStreams
    private

      def exam_streams(participations = [@participation])
        participations.flat_map { |participation| exam_row_streams(participation) } +
          exam_summary_streams + [exam_scheme_stream]
      end

      def exam_row_streams(participation)
        exam_tables.map do |table|
          row = table.row_for(participation)
          turbo_stream.replace(row.row_id, html: render_to_string(row))
        end
      end

      def exam_summary_streams
        points, grading = exam_tables
        summaries = [points.summary, grading.summary].map do |summary|
          turbo_stream.replace(summary.id, html: render_to_string(summary))
        end
        summaries << turbo_stream.replace("grading-points-changed",
                                          html: render_to_string(grading.points_changed_alert))
      end

      # An open scheme form has no "grading-scheme" target, so Turbo ignores
      # this replacement and preserves the form.
      def exam_scheme_stream
        turbo_stream.replace(
          "grading-scheme",
          html: render_to_string(partial: "assessment/assessments/components/scheme_card",
                                 locals: { assessment: @assessable.assessment })
        )
      end

      def exam_tables
        @exam_tables ||= begin
          rows = ExamRows.for(@assessable)
          [ExamPointsTableComponent.new(exam: @assessable, rows: rows),
           ExamGradingTableComponent.new(exam: @assessable, rows: rows)]
        end
      end
  end
end
