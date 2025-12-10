# generated from altcha-rails
# https://github.com/zonque/altcha-rails
Altcha.setup do |config|
  config.algorithm = "SHA-256"
  config.num_range = (50_000..500_000)
  config.timeout = 5.minutes
  config.hmac_key = ENV.fetch("CAPTCHA_HMAC_KEY")
end
