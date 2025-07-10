# Adapted from the i18n-verify gem
# https://github.com/fastcatch/i18n-verify/

namespace :i18n do
  #
  # duplicates helps in finding keys with multiple translations to the same locale
  #
  # duplicates takes a command line rake param: the list of locales to check
  #   omit for all
  #
  # Examples:
  #   rake i18n:duplicates
  #   rake i18n:duplicates locales=de,en
  #
  desc "Checks if any keys are translated multiple times"
  task duplicates: :environment do |_t, _args|
    require Rails.root.join("config/environment.rb").to_s
    require Rails.root.join("lib/tasks/i18n_verify.rb").to_s
    locales_requested = (ENV["locales"] || "").downcase.split(",")
    checker = I18nVerify::Checker.new(I18n.config.load_path)
    checker.duplicates(locales_requested)
  end
end
