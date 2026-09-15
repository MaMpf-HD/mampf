module StudentPerformance
  module RecordsHelper
    # Column headers that sort by themselves. The first click on a number asks
    # for the largest, because that is the question staff arrive with; clicking
    # the column that is already sorted turns it around. Everything else in the
    # query string travels along, so a sort does not drop the filters - only
    # the page number goes, since the first page is where the new order starts.
    def records_sort_link(lecture, column, &)
      direction = records_sort_state(column) == "descending" ? "asc" : "desc"
      query = request.query_parameters.except("page")
                     .merge("sort" => column, "dir" => direction)

      link_to(lecture_student_performance_records_path(lecture, query),
              class: "text-reset text-decoration-none",
              data: { turbo_frame: "performance-records-frame" }) do
        safe_join([capture(&), records_sort_caret(column)], " ")
      end
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
