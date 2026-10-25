class MampfsearchMetadataSyncJob < ApplicationJob
  queue_as :default

  def self.enqueue_for(media)
    media.where(transcription_status: :completed)
         .where.not(video_data: nil)
         .reorder(nil)
         .find_each { |medium| perform_later(medium.id) }
  end

  def perform(medium_id)
    return unless SearchClient.instance.configured?

    medium = Medium.find_by(id: medium_id)
    return unless medium&.transcribable? && medium.completed?

    SearchClient.instance.sync_media_hierarchy(
      medium.id,
      video_version: medium.video_fingerprint,
      hierarchy: Mampfsearch::Hierarchy.for(medium)
    )
  rescue SearchClient::MampfSearchError => e
    # MampfsearchSyncJob reconciles hierarchies that could not be synced here.
    Rails.logger.warn("Failed to sync hierarchy of medium #{medium_id} to MampfSearch: " \
                      "#{e.message}")
  end
end
