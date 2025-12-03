class CampaignStatusWorker
  include Sidekiq::Worker

  def perform
    # Auto-close campaigns that are open and have passed their deadline
    Registration::Campaign.where(status: :open)
                          .where(registration_deadline: ..Time.current)
                          .find_each do |campaign|
      campaign.update(status: :closed)
    end
  end
end
