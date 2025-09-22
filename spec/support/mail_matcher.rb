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
    return false unless mail&.html_part&.body

    body_text = Nokogiri::HTML(mail.html_part.body.to_s).text

    # Normalize whitespace in both strings before comparison.
    # This replaces all newline/tab/multiple-space sequences with a single space.
    normalized_body = body_text.squish
    normalized_expected = expected_text.squish

    normalized_body.include?(normalized_expected)
  end

  failure_message do |mail|
    if mail&.html_part&.body
      body_text = Nokogiri::HTML(mail.html_part.body.to_s).text
      "Expected the HTML body's text to include:\n  " \
        "\"#{expected_text}\"\n\n" \
        "But the parsed text was:\n  " \
        "\"#{body_text.strip}\""
    else
      "Expected email to have an HTML part, but it was nil."
    end
  end

  failure_message_when_negated do
    "Expected the HTML body's text not to include:\n  " \
      "\"#{expected_text}\"\n\n" \
      "But it was found in the parsed text."
  end
end
