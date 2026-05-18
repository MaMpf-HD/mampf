class AltchaSolutionsCleaner
  include Sidekiq::Worker

  def perform
    AltchaSolution.cleanup
  end
end
