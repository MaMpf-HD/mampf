class MampfsearchHealthJob
  include Sidekiq::Worker

  # Runs via cron anyway, so retries would only pile up on top of it.
  sidekiq_options retry: false

  def perform
    MampfsearchHealth.new.call
  end
end
