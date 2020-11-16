class MetadataExtractor
  include Sidekiq::Worker

  def perform(medium_id)
    medium = Medium.find(medium_id)
    return unless medium && medium.video.present?
    medium.video.refresh_metadata!(action: :store)
    medium.save
  end
end