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
      return form_html if !form_object.respond_to?(:errors) || form_object.errors.empty?

      doc = Nokogiri::HTML::DocumentFragment.parse(form_html)
      return form_html if doc.css(".invalid-feedback").any?

      submit_buttons = doc.css('button[type="submit"],input[type="submit"]')
      return form_html unless submit_buttons.any?

      last_submit = submit_buttons.last
      error_span = Nokogiri::HTML::DocumentFragment.parse(
        content_tag(:span, whole_form_error_text(form_object),
                    class: "invalid-feedback d-block",
                    "aria-live": "polite")
      )
      last_submit.add_next_sibling(error_span)
      log_whole_form_error(form_object)
      doc.to_html
    end

    # Which attributes had no field to show them. Nothing else records this:
    # the request completes normally, so only the attribute names say why the
    # page fell back to a whole-form message.
    def log_whole_form_error(form_object)
      codes = form_object.errors.details.transform_values do |list|
        list.map { |detail| error_code(detail[:error]) }
      end
      Rails.logger.info do
        "Form error with no field: #{form_object.class.name} #{codes.inspect}"
      end
    end

    # `errors.add` stores a message string here whenever it was given one, and
    # this helper logs for every form in the app, so a free-text message could
    # carry a submitted value into a log that filters email on purpose -- or a
    # newline that forges a line. Symbols are ours, anything else is named but
    # not repeated.
    def error_code(error)
      error.is_a?(Symbol) ? error : :custom_message
    end

    # The errors no field could show. Naming them beats the generic fallback,
    # which blames the server for what is really a validation failure.
    def whole_form_error_text(form_object)
      messages = form_object.errors.full_messages.uniq.compact_blank
      return t("errors.unknown") if messages.empty?

      # full_messages hands a :base message straight through, so a caller that
      # marked one html_safe would reach the page unescaped. Drop that flag.
      safe_join(messages.map { |message| String.new(message) }, tag.br)
    end
end
