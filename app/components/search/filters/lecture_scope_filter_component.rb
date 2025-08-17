module Search
  module Filters
    class LectureScopeFilterComponent < ViewComponent::Base
      attr_reader :form, :context

      def initialize(context: "media")
        super()
        @context = context
      end

      def with_form(form)
        @form = form
        self
      end

      def call
        content_tag(:div, class: "col-6 col-lg-4 mb-3 form-group") do
          concat(form.label(:teachable_ids, I18n.t("basics.lectures"), class: "form-label"))
          concat(helpers.helpdesk(I18n.t("search.media.lectures"), true))

          # "All" option
          concat(content_tag(:div, class: "form-check mb-2") do
            form.radio_button(:lecture_option, "0", checked: true, class: "form-check-input") +
            form.label(:lecture_option,
                       I18n.t("search.media.lecture_options.all"),
                       value: "0",
                       class: "form-check-label")
          end)

          # "Subscribed" option
          concat(content_tag(:div, class: "form-check mb-2") do
            form.radio_button(:lecture_option, "1", class: "form-check-input") +
            form.label(:lecture_option,
                       I18n.t("search.media.lecture_options.subscribed"),
                       value: "1",
                       class: "form-check-label")
          end)

          # "Own selection" option
          concat(content_tag(:div, class: "form-check mb-2") do
            form.radio_button(:lecture_option, "2",
                              class: "form-check-input",
                              data: { type: "toggle", id: "search_#{context}_lectures" }) +
            form.label(:lecture_option,
                       I18n.t("search.media.lecture_options.own_selection"),
                       value: "2",
                       class: "form-check-label")
          end)

          # Lecture selection dropdown
          concat(form.select(:media_lectures,
                             helpers.options_for_select(add_prompt(Lecture.select)),
                             {},
                             { multiple: true,
                               class: "pl-4 selectize",
                               disabled: true,
                               required: true }))
        end
      end

      private

        def add_prompt(collection)
          [[I18n.t("basics.select"), ""]] + collection
        end
    end
  end
end
