ActionView::Base.field_error_proc = proc do |html_tag, instance|
  fragment = Nokogiri::HTML.fragment(html_tag)
  field = fragment.at("input,select,textarea")
  next html_tag if field.nil?

  field.add_class("is-invalid")
  error_message = [*instance.error_message].to_sentence
  error_span = ActionController::Base.helpers.content_tag(
    :span,
    error_message,
    class: "invalid-feedback",
    aria: { live: "polite" }
  )

  html = <<-HTML
    #{fragment}
    #{error_span}
  HTML

  html.html_safe # rubocop:disable Rails/OutputSafety
end
