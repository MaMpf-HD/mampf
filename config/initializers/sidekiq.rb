schedule_file = "config/schedule.yml"

if File.exist?(schedule_file) && Sidekiq.server?
  # use the after_initialze block to avoid deprecation warning triggered
  # by zeitwerk
  # see https://github.com/ondrejbartas/sidekiq-cron/issues/249
  Rails.application.config.after_initialize do
    Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file))
  end
end
