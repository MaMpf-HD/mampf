class MampfsearchSyncJob < ApplicationJob
  queue_as :default

  def perform
    recover_stuck_jobs
    feed_next_batch
    reconcile_search_index
  end

  private

    def recover_stuck_jobs
      Medium.stuck_transcriptions.find_each do |medium|
        if medium.transcription_attempts >= SearchClient::MAX_TRANSCRIPTION_ATTEMPTS
          medium.update!(
            transcription_status: :failed_permanently,
            transcription_error: "Transcription timed out after #{SearchClient::MAX_TRANSCRIPTION_ATTEMPTS} attempts"
          )
          Rails.logger.error("Mampfsearch transcription permanently timed out for medium #{medium.id} after #{SearchClient::MAX_TRANSCRIPTION_ATTEMPTS} attempts")
        else
          medium.increment!(:transcription_attempts)
          medium.update!(
            transcription_status: :failed_temporarily,
            transcription_error: "Job timed out in worker, will retry"
          )
          Rails.logger.warn("Mampfsearch transcription timed out for medium #{medium.id} (attempt #{medium.transcription_attempts}), marked failed_temporarily")
        end
      end
    end

    def feed_next_batch
      in_flight = Medium.where(transcription_status: :queued).count
      return if in_flight >= SearchClient::MAX_IN_FLIGHT_TRANSCRIPTIONS

      batch_size = [SearchClient::SYNC_BATCH_SIZE, SearchClient::MAX_IN_FLIGHT_TRANSCRIPTIONS - in_flight].min
      Medium.needs_transcription
            .order(created_at: :desc)
            .limit(batch_size)
            .each do |medium|
              MampfsearchIngestJob.perform_later(medium.id)
            end
    end

    def reconcile_search_index
      search_ids = SearchClient.instance.list_media_rails_ids
      return unless search_ids.is_a?(Array)

      existing_video_ids = Medium.where.not(video_data: nil).pluck(:id).to_set
      indexed_ids = search_ids.to_set

      # 1. Delete orphaned media from MampfSearch (in search index but deleted or video removed in MaMpf)
      orphaned_ids = indexed_ids - existing_video_ids
      orphaned_ids.each do |orphan_id|
        MampfsearchDeleteJob.perform_later(orphan_id)
      end

      # 2. Re-ingest media marked completed in MaMpf but missing from MampfSearch index (e.g. after index reset)
      completed_ids = Medium.where.not(video_data: nil).where(transcription_status: :completed).pluck(:id).to_set
      missing_from_search = completed_ids - indexed_ids
      missing_from_search.each do |missing_id|
        MampfsearchIngestJob.perform_later(missing_id)
      end
    rescue SearchClient::MampfSearchError => e
      Rails.logger.warn("Search index reconciliation skipped (#{e.class}): #{e.message}")
    end
end
