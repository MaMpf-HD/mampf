module StudentPerformance
  module RecordsHelper
    # Column headers that sort by themselves. The first click on a number asks
    # for the largest, because that is the question staff arrive with; clicking
    # the column that is already sorted turns it around, and a third click
    # returns to the order by name. Everything else in the query string travels
    # along, so a sort does not drop the filters - only the page number goes,
    # since the first page is where the new order starts.
    def records_sort_link(lecture, column, &)
      query = request.query_parameters.except("page", "sort", "dir")
      case records_sort_state(column)
      when "none" then query = query.merge("sort" => column, "dir" => "desc")
      when "descending" then query = query.merge("sort" => column, "dir" => "asc")
      end

      link_to(lecture_student_performance_records_path(lecture, query),
              class: "text-reset text-decoration-none",
              data: { turbo_frame: "performance-records-frame" }) do
        safe_join([capture(&), records_sort_caret(column)], " ")
      end
    end

    # "passed" or "not passed" for a test's row on a student's page, nothing
    # where the test has no passing threshold or nothing is settled.
    def test_verdict_text(assessment, participation)
      verdict = assessment.assessable.test_verdict(status: participation&.status,
                                                   points_total: participation&.points_total)
      t("student_performance.records.show.test_#{verdict}") if verdict
    end

    # Spelled the way `aria-sort` wants it, so the header can pass it straight
    # on to the attribute.
    def records_sort_state(column)
      return "none" unless params[:sort] == column

      params[:dir] == "desc" ? "descending" : "ascending"
    end

    private

      def records_sort_caret(column)
        icon = case records_sort_state(column)
               when "descending" then "bi-caret-down-fill"
               when "ascending" then "bi-caret-up-fill"
               else "bi-chevron-expand text-muted opacity-50"
        end

        tag.i(class: "bi #{icon} small", aria: { hidden: true })
      end
  end
end
