# generated from altcha-rails
# https://github.com/zonque/altcha-rails
Altcha.setup do |config|
  config.algorithm = "SHA-256"
  # The browser tries numbers up to this one, so in tests, where many browsers
  # share the machine, a small one keeps the sign-up within the test timeouts.
  config.max_number = Rails.env.test? ? 1_000 : 300_000
  config.timeout = 4.minutes
  config.hmac_key = ENV.fetch("CAPTCHA_HMAC_KEY")
end
