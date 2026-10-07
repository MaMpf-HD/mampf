class MampfsearchMetadataSyncJob < ApplicationJob
  queue_as :default

  def self.enqueue_for(media)
    media.where(transcription_status: :completed)
         .where.not(video_data: nil)
         .reorder(nil)
         .find_each { |medium| perform_later(medium.id) }
  end

  def perform(medium_id)
    medium = Medium.find_by(id: medium_id)
    return unless medium&.transcribable? && medium.completed?

    SearchClient.instance.sync_media_hierarchy(
      medium.id,
      video_version: medium.video_fingerprint,
      hierarchy: Mampfsearch::Hierarchy.for(medium)
    )
  end
end
