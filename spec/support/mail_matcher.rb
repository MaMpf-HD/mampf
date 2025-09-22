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
  @body_doc = nil

  match do |mail|
    return false unless mail&.html_part&.body

    # Parse the document once and store the Nokogiri object.
    # The .to_s is kept for clarity and safety, ensuring a string is passed to Nokogiri.
    @body_doc = Nokogiri::HTML(mail.html_part.body.to_s)
    body_text = @body_doc.text

    # Normalize whitespace in both strings before comparison.
    normalized_body = body_text.squish
    normalized_expected = expected_text.squish

    normalized_body.include?(normalized_expected)
  end

  failure_message do
    if @body_doc
      "Expected the HTML body's text to include:\n  " \
        "\"#{expected_text.squish}\"\n\n" \
        "But the parsed text was:\n  " \
        "\"#{@body_doc.text.squish}\""
    else
      "Expected email to have an HTML part, but it was nil."
    end
  end

  failure_message_when_negated do
    parsed_text = @body_doc ? @body_doc.text.squish : ""
    "Expected the HTML body's text not to include:\n  " \
      "\"#{expected_text.squish}\"\n\n" \
      "But it was found in the parsed text:\n  " \
      "\"#{parsed_text}\""
  end
end
