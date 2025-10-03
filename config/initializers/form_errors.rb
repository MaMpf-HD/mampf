# Customizes how validation errors are rendered in views.
#
# - Rails guide:
#   https://guides.rubyonrails.org/active_record_validations.html#displaying-validation-errors-in-views
# - My blog post:
#   https://splines.me/blog/2025/server-side-validation-rails-turbo#customize-how-errors-are-rendered
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
