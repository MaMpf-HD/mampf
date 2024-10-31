RSpec::Matchers.define(:enqueue_mail_with_params) do |mailer, method, params|
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

RSpec::Matchers.define(:include_in_html_body) do |expected|
  # ignore \r and \n in the comparison
  mail_body_stripped = ->(mail) { mail.html_part.body.decoded.gsub(/[\r\n]/, "") }
  expected_stripped = expected.gsub(/[\r\n]/, "")

  match do |mail|
    mail_body_stripped.call(mail).include?(expected_stripped)
  end

  failure_message do |mail|
    "Expected that the HTML body would include:\n#{expected_stripped}\n" \
      + "But got:\n#{mail_body_stripped.call(mail)}"
  end
end
