module Assessment
  # The Turbo Streams every write to an exam's row answers with. The same
  # participation stands in the points table and in the grading table, and
  # the scheme card beside them counts the grades, so all of them are redrawn
  # from one reading of the roster.
  module ExamStreams
    private

      def exam_streams
        exam_row_streams + exam_summary_streams + [exam_scheme_stream]
      end

      def exam_row_streams
        exam_tables.map do |table|
          row = table.row_for(@participation)
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

      # The card is only on the page while no scheme form is open; a replace
      # without a target is a no-op, so the form is never torn down.
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
          [ExamPointingTableComponent.new(exam: @assessable, rows: rows),
           ExamGradingTableComponent.new(exam: @assessable, rows: rows)]
        end
      end
  end
end
