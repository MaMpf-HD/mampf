# Customizes how validation errors are rendered in views.
#
# - Rails guide:
#   https://guides.rubyonrails.org/active_record_validations.html#displaying-validation-errors-in-views
# - My blog post:
#   https://splines.me/blog/2025/server-side-validation-rails-turbo#customize-how-errors-are-rendered
ActionView::Base.field_error_proc = proc do |html_tag, instance|
  next html_tag if ActiveSupport::IsolatedExecutionState[:bootstrap_form]

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

# bootstrap_form renders its own field errors and swaps the process-wide
# field_error_proc for a no-op while it does; two Puma threads doing that at
# once leave the no-op behind, and no form shows field errors until a restart.
# This keeps the swap to the request that renders the bootstrap form.
module BootstrapFormFieldErrorsPerRequest
  private

    def with_bootstrap_form_field_error_proc
      outer = ActiveSupport::IsolatedExecutionState[:bootstrap_form]
      ActiveSupport::IsolatedExecutionState[:bootstrap_form] = true
      yield
    ensure
      ActiveSupport::IsolatedExecutionState[:bootstrap_form] = outer
    end
end

BootstrapForm::ActionViewExtensions::FormHelper.prepend(BootstrapFormFieldErrorsPerRequest)
