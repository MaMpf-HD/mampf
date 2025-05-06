Rails.application.config.active_job.queue_adapter = :sidekiq unless Rails.env.test?
