# See my blog post for more details:
# https://splines.me/blog/2025/server-side-validation-rails-turbo#bonus-general-form-errors
module FormUnknownErrorHelper
  # Overrides form_with to show a general form error message if the form
  # has errors but no field-specific errors shown on the page.
  def form_with(**options, &)
    # Render the form to a string
    form_html = capture do
      super(**options, &)
    end

    form_object = options[:model] || options[:scope]
    form_html = add_whole_form_error_message(form_object, form_html)

    form_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  private

    # Adds a general form error message if the form object has errors but
    # no field-specific error markup is present.
    def add_whole_form_error_message(form_object, form_html)
      if !form_object.respond_to?(:errors) || form_object.errors.empty? \
        || form_html.include?('class="invalid-feedback"')
        return form_html
      end

      doc = Nokogiri::HTML::DocumentFragment.parse(form_html)
      submit_buttons = doc.css('button[type="submit"],input[type="submit"]')
      return form_html unless submit_buttons.any?

      last_submit = submit_buttons.last
      error_span = Nokogiri::HTML::DocumentFragment.parse(
        content_tag(:span, t("errors.unknown"),
                    class: "invalid-feedback d-block",
                    "aria-live": "polite")
      )
      last_submit.add_next_sibling(error_span)
      doc.to_html
    end
end
