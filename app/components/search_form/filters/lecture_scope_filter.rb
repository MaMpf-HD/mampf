module SearchForm
  module Filters
    class LectureScopeFilter < Fields::MultiSelectField
      def initialize(**)
        super(
          name: :lectures,
          label: I18n.t("basics.lectures"),
          help_text: I18n.t("search.media.lectures"),
          collection: Lecture.select,
          **
        )

        @show_radio_group = false
      end

      def with_lecture_options
        @show_radio_group = true
        self
      end

      def show_radio_group?
        @show_radio_group
      end

      def render_radio_group
        return unless show_radio_group?

        builder = Builders::RadioGroupFactories::LectureOptionsRadios.build(form_state)
        render(builder.build_radio_group)
      end

      # We don't want the all checkbox for this component
      def show_checkbox?
        false
      end
    end
  end
end
