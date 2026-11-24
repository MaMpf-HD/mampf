class MampfsearchHealthJob
  include Sidekiq::Worker

  def perform
    MampfsearchHealth.new.call
  end
end
