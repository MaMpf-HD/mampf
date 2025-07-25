module FilterableByCourse
  extend ActiveSupport::Concern

  class_methods do
    private

      def apply_course_filter(scope, params)
        if params[:all_courses] == "1" || params[:course_ids].blank? || params[:course_ids] == [""]
          return scope
        end

        scope.by_courses(params[:course_ids])
      end
  end

  included do
    scope :by_courses, lambda { |course_ids|
      joins(:course_tag_joins).where(course_tag_joins: { course_id: course_ids }).distinct
    }
  end
end
