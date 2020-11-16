class MetadataExtractor
  include Sidekiq::Worker

  def perform(medium_id)
    medium = Medium.find(medium_id)
    return unless medium && medium.video.present?
    medium.video.refresh_metadata!(action: :store)
    refreshed_video = medium.video
    medium.update(video_data: refreshed_video.to_json)
  end
end