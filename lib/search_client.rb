require "http"
require "connection_pool"
require "singleton"

class SearchClient
  include Singleton

  MAX_TRANSCRIPTION_ATTEMPTS = 3
  STUCK_TRANSCRIPTION_TIMEOUT = 2.hours
  MAX_IN_FLIGHT_TRANSCRIPTIONS = 15
  SYNC_BATCH_SIZE = 10

  class MampfSearchError < StandardError; end

  class ServiceUnavailableError < MampfSearchError; end
  class TimeoutError < MampfSearchError; end

  class InvalidQueryError < MampfSearchError; end
  class InvalidResponseError < MampfSearchError; end

  def initialize(base_url: ENV["MAMPFSEARCH_BASE_URL"].presence, pool_size: 5, timeout_seconds: 5)
    @base_url = base_url
    @timeout = timeout_seconds

    return if @base_url.blank?

    @pool = ConnectionPool.new(size: pool_size, timeout: @timeout) do
      HTTP.persistent(@base_url)
          .timeout(connect: @timeout, write: @timeout, read: @timeout)
          .headers(accept: "application/json", content_type: "application/json")
    end
  end

  # rubocop:disable Metrics/ParameterLists
  def transcribe_lesson(media_rails_id:, course_rails_id:, video_url:,
                        transcript_upload_url:, transcription_failed_url: nil,
                        lecture_rails_id: nil, lesson_rails_id: nil)
    payload = {
      media_rails_id: media_rails_id,
      course_rails_id: course_rails_id,
      video_url: video_url,
      transcript_upload_url: transcript_upload_url
    }
    if transcription_failed_url.present?
      payload[:transcription_failed_url] =
        transcription_failed_url
    end

    payload[:lecture_rails_id] = lecture_rails_id if lecture_rails_id.present?
    payload[:lesson_rails_id] = lesson_rails_id if lesson_rails_id.present?

    perform_request(scope: "/lesson/ingest") do |client|
      client.post("/lesson/ingest", params: payload)
    end
  end
  # rubocop:enable Metrics/ParameterLists

  def delete_media(media_rails_id)
    perform_request(scope: "/lesson/media/#{media_rails_id}") do |client|
      client.delete("/lesson/media/#{media_rails_id}")
    end
  end

  def list_media_rails_ids
    response = perform_request(scope: "/lesson/list") do |client|
      client.post("/lesson/list")
    end
    response.is_a?(Hash) ? response.fetch("media_rails_ids", []) : []
  end

  def health
    perform_request do |client|
      client.get("/ready")
    end
  end

  private

    def perform_request(scope: nil)
      unless @pool
        raise(ServiceUnavailableError,
              "MampfSearch is not configured (MAMPFSEARCH_BASE_URL is missing)")
      end

      response = @pool.with do |client|
        request_client = if scope
          token = SearchApiToken.generate(scope: scope)
          client.headers(authorization: "Bearer #{token}")
        else
          client
        end
        yield(request_client)
      end
      handle_response(response)
    rescue HTTP::TimeoutError
      raise(TimeoutError, "The search microservice timed out.")
    rescue HTTP::Error, SystemCallError, SocketError => e
      raise(ServiceUnavailableError, "The search service is currently offline: #{e.message}")
    rescue JSON::ParserError => e
      raise(InvalidResponseError, "The search service returned a non-JSON response: #{e.message}")
    end

    def handle_response(response)
      case response.status.code
      when 200..299
        JSON.parse(response.body.to_s)
      when 400..422
        raise(InvalidQueryError, "Invalid search parameters (HTTP #{response.status.code}).")
      when 500..599
        raise(InvalidResponseError,
              "The search engine encountered an internal error (HTTP #{response.status.code}).")
      else
        raise(MampfSearchError, "Unexpected search failure (HTTP #{response.status.code}).")
      end
    end
end
