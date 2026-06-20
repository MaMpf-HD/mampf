namespace :db do
  namespace :migrate do
    desc "Run db:migrate in development with strong_migrations checks enabled"
    task :strong do
      rails_env = ENV.fetch("RAILS_ENV", "development")

      unless rails_env == "development"
        abort "db:migrate:strong only supports RAILS_ENV=development"
      end

      success = system(
        {
          "RAILS_ENV" => rails_env,
          "STRONG_MIGRATIONS_CHECKS" => "1"
        },
        "bundle", "exec", "rails", "db:migrate"
      )

      abort "db:migrate:strong failed" unless success
    end
  end
end
