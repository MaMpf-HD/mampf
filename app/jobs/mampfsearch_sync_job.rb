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
            transcription_error: "Transcription timed out after " \
                                 "#{SearchClient::MAX_TRANSCRIPTION_ATTEMPTS} attempts"
          )
          Rails.logger.error("Mampfsearch transcription permanently timed out for medium " \
                             "#{medium.id} after " \
                             "#{SearchClient::MAX_TRANSCRIPTION_ATTEMPTS} attempts")
        else
          medium.update!(
            transcription_attempts: medium.transcription_attempts + 1,
            transcription_status: :failed_temporarily,
            transcription_error: "Job timed out in worker, will retry"
          )
          Rails.logger.warn(
            "Mampfsearch transcription timed out for medium #{medium.id} " \
            "(attempt #{medium.transcription_attempts}), marked failed_temporarily"
          )
        end
      end
    end

    def feed_next_batch
      enqueue_batch(Medium.needs_transcription)
    end

    def reconcile_search_index
      search_versions = SearchClient.instance.list_media_versions
      return unless search_versions.is_a?(Hash)

      current_media = Medium.where.not(video_data: nil).index_by(&:id)
      indexed_ids = search_versions.keys.to_set

      # 1. Invalidate orphaned or outdated index entries without deleting newer versions.
      search_versions.each do |id, indexed_version|
        medium = current_media[id]
        next if medium && medium.video_fingerprint == indexed_version

        invalidated = SearchClient.instance.invalidate_media(
          id, expected_video_version: indexed_version
        )
        indexed_ids.delete(id) if invalidated
      end

      # 2. Re-ingest media marked completed in MaMpf but missing from index (e.g. after reset)
      completed_ids = current_media.values.select(&:completed?).to_set(&:id)
      missing_from_search = completed_ids - indexed_ids
      return if missing_from_search.empty?

      enqueue_batch(Medium.where(id: missing_from_search))
    rescue SearchClient::MampfSearchError => e
      Rails.logger.warn("Search index reconciliation skipped (#{e.class}): #{e.message}")
    end

    def enqueue_batch(relation)
      batch_size = available_batch_capacity
      return if batch_size.zero?

      relation.order(created_at: :desc)
              .limit(batch_size)
              .each do |medium|
        claim_and_enqueue(medium)
      end
    end

    def available_batch_capacity
      in_flight = Medium.where(transcription_status: :queued).count
      return 0 if in_flight >= SearchClient::MAX_IN_FLIGHT_TRANSCRIPTIONS

      [SearchClient::SYNC_BATCH_SIZE,
       SearchClient::MAX_IN_FLIGHT_TRANSCRIPTIONS - in_flight].min
    end

    def claim_and_enqueue(medium)
      claimed = false
      medium.with_lock do
        unless medium.queued?
          medium.update!(
            transcription_status: :queued,
            transcription_requested_at: Time.current,
            transcription_error: nil
          )
          claimed = true
        end
      end
      MampfsearchIngestJob.perform_later(medium.id) if claimed
      claimed
    end
end
