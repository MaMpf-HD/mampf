class MampfsearchIngestJob < ApplicationJob
  queue_as :default

  def perform(medium_id)
    medium = Medium.find_by(id: medium_id)
    return unless medium&.transcribable?

    medium.update!(
      transcription_status: :queued,
      transcription_requested_at: Time.current,
      transcription_error: nil
    )
    Mampfsearch::IngestionService.transcribe(medium)
  rescue StandardError => e
    fail_transcription(medium, e.message)
  end

  private

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
