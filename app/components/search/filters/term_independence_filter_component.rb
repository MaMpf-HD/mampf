module Search
  module Filters
    class TermIndependenceFilterComponent < ViewComponent::Base
      def call
        tag.div(class: "col-6 col-lg-3 mb-3") do
          tag.div(class: "form-check mb-2") do
            form.check_box(:term_independent, class: "form-check-input") +
              form.label(:term_independent,
                         I18n.t("admin.course.term_independent"),
                         class: "form-check-label")
          end
        end
      end

      private

        attr_reader :form

        def initialize
          super
        end

        def with_form(form)
          @form = form
          self
        end
    end
  end
end
