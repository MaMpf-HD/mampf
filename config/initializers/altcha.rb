# generated from altcha-rails
# https://github.com/zonque/altcha-rails
Altcha.setup do |config|
  config.algorithm = "SHA-256"
  config.num_range = (70_000..300_000)
  config.timeout = 4.minutes
  config.hmac_key = ENV.fetch("CAPTCHA_HMAC_KEY")
end
