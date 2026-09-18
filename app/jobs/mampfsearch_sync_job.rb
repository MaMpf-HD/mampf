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
        attempts = medium.transcription_attempts + 1

        if attempts >= SearchClient::MAX_TRANSCRIPTION_ATTEMPTS
          medium.update!(
            transcription_attempts: attempts,
            transcription_status: :failed_permanently,
            transcription_error: "Transcription timed out after " \
                                 "#{attempts} attempts"
          )
          Rails.logger.error("Mampfsearch transcription permanently timed out for medium " \
                             "#{medium.id} after " \
                             "#{attempts} attempts")
        else
          medium.update!(
            transcription_attempts: attempts,
            transcription_status: :failed_temporarily,
            transcription_error: "Transcription timed out in worker, will retry"
          )
          Rails.logger.warn(
            "Mampfsearch transcription timed out for medium #{medium.id} " \
            "(attempt #{attempts}), marked failed_temporarily"
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
      # 1. Invalidate orphaned or outdated index entries without deleting newer versions.
      indexed_ids = invalidate_outdated_index_entries(search_versions, current_media)
      # 2. Re-ingest media marked completed in MaMpf but missing from index (e.g. after reset)
      completed_ids = current_media.values.select(&:completed?).to_set(&:id)
      missing_from_search = completed_ids - indexed_ids
      enqueue_batch(Medium.where(id: missing_from_search)) if missing_from_search.any?
      # 3. Update indexed media whose hierarchy changed without re-ingesting the video.
      reconcile_hierarchies(current_media, search_versions, indexed_ids)
    rescue SearchClient::MampfSearchError => e
      Rails.logger.warn("Search index reconciliation skipped (#{e.class}): #{e.message}")
    end

    def invalidate_outdated_index_entries(search_versions, current_media)
      indexed_ids = search_versions.keys.to_set
      search_versions.each do |id, indexed_version|
        medium = current_media[id]
        next if medium && medium.video_fingerprint == indexed_version

        invalidated = SearchClient.instance.invalidate_media(
          id, expected_video_version: indexed_version
        )
        indexed_ids.delete(id) if invalidated
      end
      indexed_ids
    end

    def reconcile_hierarchies(current_media, search_versions, indexed_ids)
      search_hierarchies = SearchClient.instance.list_media_hierarchies
      return unless search_hierarchies.is_a?(Hash)

      indexed_ids.each do |id|
        medium = current_media[id]
        next unless medium&.completed?
        next unless medium.video_fingerprint == search_versions[id]

        hierarchy = Mampfsearch::Hierarchy.for(medium)
        course_id, lecture_id, lesson_id = hierarchy.values_at(
          :course_rails_id, :lecture_rails_id, :lesson_rails_id
        )
        expected = [course_id, lecture_id, lesson_id,
                    lecture_id ? course_id : nil,
                    lesson_id ? lecture_id : nil]
        next if search_hierarchies[id] == expected

        MampfsearchMetadataSyncJob.perform_later(id)
      end
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
          unless medium.completed?
            medium.update!(
              transcription_status: :queued,
              transcription_requested_at: Time.current,
              transcription_error: nil
            )
          end
          claimed = true
        end
      end
      MampfsearchIngestJob.perform_later(medium.id) if claimed
      claimed
    end
end
