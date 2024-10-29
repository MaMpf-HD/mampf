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
