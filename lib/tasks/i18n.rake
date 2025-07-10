namespace :i18n do
  desc "Checks for duplicate translations in the i18n files"
  task duplicates: :environment do |_t, _args|
    require Rails.root.join("config/environment.rb").to_s
    require Rails.root.join("lib/tasks/i18n_verify.rb").to_s
    checker = I18nVerify::Checker.new(I18n.config.load_path)
    checker.duplicates
  end
end
