module Search
  class CourseFilter < BaseFilter
    def call
      if params[:all_courses] == "1" || params[:course_ids].blank? || params[:course_ids] == [""]
        return scope
      end

      scope.joins(:courses)
           .where(courses: { id: params[:course_ids] })
           .distinct
    end
  end
end
