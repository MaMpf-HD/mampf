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

        # These options match what's in the original partial
        options.reverse_merge!(
          multiple: true,
          class: "pl-4 selectize",
          disabled: true,
          required: true
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

      def render_lecture_options
        content_tag(:div, class: "mt-2") do
          safe_join([
                      # "Own selection" option
                      content_tag(:div, class: "form-check mb-2") do
                        form.radio_button(:lecture_option, "2",
                                          class: "form-check-input",
                                          data: { type: "toggle",
                                                  id: "search_#{context}_lectures" }) +
                        form.label(:lecture_option,
                                   I18n.t("search.media.lecture_options.own_selection"),
                                   value: "2",
                                   class: "form-check-label")
                      end,

                      # "Subscribed" option
                      content_tag(:div, class: "form-check mb-2") do
                        form.radio_button(:lecture_option, "1",
                                          class: "form-check-input") +
                        form.label(:lecture_option,
                                   I18n.t("search.media.lecture_options.subscribed"),
                                   value: "1",
                                   class: "form-check-label")
                      end,

                      # "All" option
                      content_tag(:div, class: "form-check mb-2") do
                        form.radio_button(:lecture_option, "0",
                                          checked: true,
                                          class: "form-check-input") +
                        form.label(:lecture_option,
                                   I18n.t("search.media.lecture_options.all"),
                                   value: "0",
                                   class: "form-check-label")
                      end
                    ])
        end
      end
    end
  end
end
