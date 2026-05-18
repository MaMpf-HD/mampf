require "nokogiri"

RSpec::Matchers.define(:enqueue_mail_including_params) do |mailer, method, params|
  supports_block_expectations

  match do |block|
    expect do
      block.call
    end.to have_enqueued_mail(mailer, method)
      .with(hash_including(params: hash_including(params)))
  end

  failure_message do |_block|
    "expected to enqueue #{mailer}.#{method} with #{params}, but instead enqueued: #{enqueued_jobs}"
  end
end

RSpec::Matchers.define(:include_in_html_body) do |expected_text|
  match do |mail|
    if mail.html_part.nil? || mail.html_part.body.blank?
      @missing_html_body = true
      false
    else
      html_body = mail.html_part.body.to_s
      @body_doc = Nokogiri::HTML(html_body)
      body_text = @body_doc.text

      normalized_body = body_text.squish
      normalized_expected = expected_text.squish

      normalized_body.include?(normalized_expected)
    end
  end

  failure_message do
    if @missing_html_body
      if @mail.html_part.nil?
        "expected email to have an HTML part, but it was nil."
      else
        "expected email to have a non-empty HTML body, but it was empty."
      end
    else
      "Expected the HTML body's text to include:\n  " \
        "\"#{expected_text.squish}\"\n\n" \
        "But the parsed text was:\n  " \
        "\"#{@body_doc.text.squish}\""
    end
  end

  failure_message_when_negated do
    if @missing_html_body
      "expected email NOT to have an HTML body, but HTML body check failed."
    else
      "Expected the HTML body's text NOT to include:\n  " \
        "\"#{expected_text.squish}\"\n\n" \
        "But it was found in the parsed text:\n  " \
        "\"#{@body_doc.text.squish}\""
    end
  end
end
