class MampfsearchIngestJob < ApplicationJob
  queue_as :default

  def perform(medium_id)
    medium = Medium.find_by(id: medium_id)
    return unless medium&.transcribable?
    return release_transcription(medium, "MampfSearch cannot ingest") unless ingest_available?

    unless medium.completed?
      medium.update!(
        transcription_status: :queued,
        transcription_requested_at: Time.current,
        transcription_error: nil
      )
    end
    Mampfsearch::IngestionService.transcribe(medium)
  rescue SearchClient::ServiceUnavailableError => e
    release_transcription(medium, e.message)
  rescue StandardError => e
    fail_transcription(medium, e.message)
  end

  private

    def ingest_available?
      SearchClient.instance.configured? && MampfsearchHealth.ingest_available?
    end

    # Hands a queued medium back to the scheduler without counting an attempt:
    # the service is unavailable, not the medium broken.
    def release_transcription(medium, error)
      return unless medium&.queued?

      medium.update!(
        transcription_status: :not_transcribed,
        transcription_requested_at: nil,
        transcription_error: error
      )
      Rails.logger.warn("Mampfsearch released Medium #{medium.id} without counting " \
                        "an attempt: #{error}")
    end

    def fail_transcription(medium, error)
      return unless medium

      attempts = medium.transcription_attempts + 1
      status = if attempts >= SearchClient::MAX_TRANSCRIPTION_ATTEMPTS
        :failed_permanently
      else
        :failed_temporarily
      end

      medium.update!(
        transcription_attempts: attempts,
        transcription_status: status,
        transcription_error: error
      )

      if status == :failed_permanently
        Rails.logger.error("Mampfsearch transcription permanently failed for Medium " \
                           "#{medium.id}: #{error}")
      else
        Rails.logger.warn("Mampfsearch transcription failed for Medium #{medium.id} " \
                          "(attempt #{attempts}): #{error}")
      end
    end
end
