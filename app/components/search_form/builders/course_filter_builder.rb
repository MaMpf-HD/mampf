module SearchForm
  module Builders
    class CourseFilterBuilder
      def initialize(form_state)
        @form_state = form_state
        @filter = Filters::CourseFilter.new
        @filter.form_state = form_state
      end

      def with_edited_courses_button(current_user)
        # Call the method directly and add the result as content
        button_html = @filter.render_edited_courses_button(current_user)
        @filter.with_content do
          button_html
        end
        self
      end

      def build
        @filter
      end
    end
  end
end
