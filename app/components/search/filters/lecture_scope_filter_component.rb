module Search
  module Filters
    class LectureScopeFilterComponent < Search::MultiSelectComponent
      def initialize(context: "media", **)
        super(
          name: :lectures,
          label: I18n.t("basics.lectures"),
          help_text: I18n.t("search.media.lectures"),
          collection: [], # Will be populated in before_render
          all_toggle_name: nil, # We don't want the default "All" checkbox
          column_class: "col-6 col-lg-4",
          context: context,
          **
        )
      end

      # Load collection just in time (helpers available now)
      def before_render
        super
        @collection = helpers.add_prompt(Lecture.select)
      end

      # We don't want the all checkbox for this component
      def skip_all_checkbox?
        true
      end

      # Render lecture options using block-based approach
      def render_lecture_options
        render(Search::Controls::RadioGroupComponent.new(
                 form: form,
                 name: :lecture_option
               )) do |group|
          group.with_radio_button(
            form: form,
            name: :lecture_option,
            value: "0",
            label: I18n.t("search.media.lecture_options.all"),
            checked: true,
            stimulus: { radio_toggle: true, controls_select: false }
          )

          group.with_radio_button(
            form: form,
            name: :lecture_option,
            value: "1",
            label: I18n.t("search.media.lecture_options.subscribed"),
            stimulus: { radio_toggle: true, controls_select: false }
          )

          group.with_radio_button(
            form: form,
            name: :lecture_option,
            value: "2",
            label: I18n.t("search.media.lecture_options.own_selection"),
            stimulus: { radio_toggle: true, controls_select: true }
          )
        end
      end
    end
  end
end
