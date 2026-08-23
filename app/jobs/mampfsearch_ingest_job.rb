class MampfsearchIngestJob < ApplicationJob
  queue_as :default

  def perform(medium_id)
    medium = Medium.find_by(id: medium_id)
    unless medium
      Rails.logger.warn("Skipping MampfsearchIngestJob: Medium #{medium_id} not found.")
      return
    end

    unless medium.transcribable?
      Rails.logger.info("Skipping MampfsearchIngestJob for Medium #{medium_id}: " \
                        "not transcribable (no video attached).")
      return
    end

    if medium.failed_temporarily? &&
       medium.transcription_attempts >= SearchClient::MAX_TRANSCRIPTION_ATTEMPTS
      medium.update!(
        transcription_status: :failed_permanently,
        transcription_error: "Exceeded max transcription attempts " \
                             "(#{medium.transcription_attempts}/" \
                             "#{SearchClient::MAX_TRANSCRIPTION_ATTEMPTS})."
      )
      Rails.logger.warn("Mampfsearch transcription permanently failed for Medium #{medium.id}: " \
                        "exceeded max attempts (#{medium.transcription_attempts}).")
      return
    end

    begin
      medium.update!(
        transcription_status: :queued,
        transcription_requested_at: Time.current,
        transcription_error: nil
      )
      Mampfsearch::IngestionService.transcribe(medium)
    rescue SearchClient::ServiceUnavailableError, SearchClient::TimeoutError => e
      medium.update!(
        transcription_attempts: medium.transcription_attempts + 1,
        transcription_status: :failed_temporarily,
        transcription_error: "MampfSearch temporarily unavailable: #{e.message}"
      )
      Rails.logger.warn("Mampfsearch transcription temporarily failed for Medium #{medium.id} " \
                        "(attempt #{medium.transcription_attempts}): #{e.message}")
    rescue SearchClient::MampfSearchError => e
      medium.update!(
        transcription_attempts: medium.transcription_attempts + 1,
        transcription_status: :failed_permanently,
        transcription_error: "Fatal API error: #{e.message}"
      )
      Rails.logger.error("Mampfsearch transcription permanently failed for " \
                         "Medium #{medium.id}: #{e.message}")
    end
  end
end
