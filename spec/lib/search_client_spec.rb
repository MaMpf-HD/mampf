require "rails_helper"

RSpec.describe(SearchClient, :mampfsearch) do
  let(:base_url) { "http://localhost:8000" }
  let(:client) { described_class.send(:new, base_url: base_url) }

  describe "#initialize" do
    it "uses MAMPFSEARCH_BASE_URL env var by default" do
      original = ENV.fetch("MAMPFSEARCH_BASE_URL", nil)
      begin
        ENV["MAMPFSEARCH_BASE_URL"] = "http://example.com:8000"
        instance = described_class.send(:new)
        expect(instance.instance_variable_get(:@base_url)).to eq("http://example.com:8000")
      ensure
        ENV["MAMPFSEARCH_BASE_URL"] = original
      end
    end
  end

  describe "#transcribe_lesson" do
    let(:pool) { client.instance_variable_get(:@pool) }

    def fake_response(code, body)
      status = double("status", code: code)
      double("response", status: status, body: double("body", to_s: body))
    end

    it "posts to /lesson/ingest with correct parameters" do
      fake_client = double("client")
      allow(fake_client).to receive(:headers).and_return(fake_client)
      expect(fake_client).to receive(:post).with("/lesson/ingest", params: {
                                                   media_rails_id: 1,
                                                   lecture_rails_id: 2,
                                                   course_rails_id: 3,
                                                   video_url: "http://video.url",
                                                   transcript_upload_url: "http://upload.url"
                                                 }).and_return(fake_response(200,
                                                                             '{"status":"queued"}'))

      allow(pool).to receive(:with) { |&block| block.call(fake_client) }

      response = client.transcribe_lesson(
        media_rails_id: 1,
        lecture_rails_id: 2,
        course_rails_id: 3,
        video_url: "http://video.url",
        transcript_upload_url: "http://upload.url"
      )

      expect(response).to eq("status" => "queued")
    end

    it "omits nil lecture_rails_id and lesson_rails_id from payload in transcribe_lesson" do
      fake_http = double("http")
      allow(fake_http).to receive(:headers).and_return(fake_http)
      expect(fake_http).to receive(:post).with("/lesson/ingest", params: {
                                                 media_rails_id: 1,
                                                 course_rails_id: 3,
                                                 video_url: "http://video.url",
                                                 transcript_upload_url: "http://upload.url"
                                               }).and_return(fake_response(200,
                                                                           '{"status":"queued"}'))

      allow(pool).to receive(:with) { |&block| block.call(fake_http) }

      client.transcribe_lesson(
        media_rails_id: 1, course_rails_id: 3,
        video_url: "http://video.url", transcript_upload_url: "http://upload.url"
      )
    end

    it "raises TimeoutError on HTTP timeout" do
      fake_client = double("client")
      allow(fake_client).to receive(:headers).and_return(fake_client)
      allow(fake_client).to receive(:post).and_raise(HTTP::TimeoutError)
      allow(pool).to receive(:with) { |&block| block.call(fake_client) }

      expect do
        client.transcribe_lesson(
          media_rails_id: 1, course_rails_id: 3,
          video_url: "http://video.url", transcript_upload_url: "http://upload.url"
        )
      end.to raise_error(SearchClient::TimeoutError)
    end

    it "includes the transcription failure callback URL when provided" do
      fake_client = double("client")
      allow(fake_client).to receive(:headers).and_return(fake_client)
      expect(fake_client).to receive(:post).with("/lesson/ingest", params: hash_including(
        transcription_failed_url: "http://failure.url"
      )).and_return(fake_response(200,
                                  '{"status":"queued"}'))

      allow(pool).to receive(:with) { |&block| block.call(fake_client) }

      client.transcribe_lesson(
        media_rails_id: 1,
        course_rails_id: 3,
        video_url: "http://video.url",
        transcript_upload_url: "http://upload.url",
        transcription_failed_url: "http://failure.url"
      )
    end

    it "raises ServiceUnavailableError on connection failure" do
      fake_client = double("client")
      allow(fake_client).to receive(:headers).and_return(fake_client)
      allow(fake_client).to receive(:post).and_raise(HTTP::ConnectionError)
      allow(pool).to receive(:with) { |&block| block.call(fake_client) }

      expect do
        client.transcribe_lesson(
          media_rails_id: 1, course_rails_id: 3,
          video_url: "http://video.url", transcript_upload_url: "http://upload.url"
        )
      end.to raise_error(SearchClient::ServiceUnavailableError)
    end
  end

  describe "#delete_media" do
    let(:pool) { client.instance_variable_get(:@pool) }

    def fake_response(code, body)
      status = double("status", code: code)
      double("response", status: status, body: double("body", to_s: body))
    end

    it "sends DELETE to /lesson/media/:id" do
      fake_client = double("client")
      allow(fake_client).to receive(:headers).and_return(fake_client)
      expect(fake_client).to receive(:delete).with("/lesson/media/42")
                                             .and_return(
                                               fake_response(
                                                 200,
                                                 '{"status":"deleted","media_rails_id":42}'
                                               )
                                             )

      allow(pool).to receive(:with) { |&block| block.call(fake_client) }

      response = client.delete_media(42)
      expect(response).to eq("status" => "deleted", "media_rails_id" => 42)
    end
  end

  describe "#list_media_rails_ids" do
    let(:pool) { client.instance_variable_get(:@pool) }

    def fake_response(code, body)
      status = double("status", code: code)
      double("response", status: status, body: double("body", to_s: body))
    end

    it "posts to /lesson/list and returns the media_rails_ids array" do
      fake_client = double("client")
      allow(fake_client).to receive(:headers).and_return(fake_client)
      expect(fake_client).to receive(:post).with("/lesson/list")
                                           .and_return(fake_response(200,
                                                                     '{"media_rails_ids":[1,2,3]}'))

      allow(pool).to receive(:with) { |&block| block.call(fake_client) }

      expect(client.list_media_rails_ids).to eq([1, 2, 3])
    end

    it "returns empty array when media_rails_ids key is missing" do
      fake_client = double("client")
      allow(fake_client).to receive(:headers).and_return(fake_client)
      expect(fake_client).to receive(:post).with("/lesson/list")
                                           .and_return(fake_response(200, "{}"))

      allow(pool).to receive(:with) { |&block| block.call(fake_client) }

      expect(client.list_media_rails_ids).to eq([])
    end
  end

  describe "#health" do
    let(:pool) { client.instance_variable_get(:@pool) }

    def fake_response(code, body)
      status = double("status", code: code)
      double("response", status: status, body: double("body", to_s: body))
    end

    it "returns the parsed readiness payload" do
      payload = '{"status":"ok","capabilities":{"search":true,"ingest":true}}'
      fake_client = double("client", get: fake_response(200, payload))
      allow(pool).to receive(:with) { |&block| block.call(fake_client) }

      health = client.health

      expect(health).to eq("status" => "ok",
                           "capabilities" => { "search" => true, "ingest" => true })
    end

    it "raises InvalidResponseError on a non-JSON response" do
      fake_client = double("client", get: fake_response(200, "<html>error</html>"))
      allow(pool).to receive(:with) { |&block| block.call(fake_client) }

      expect { client.health }
        .to raise_error(SearchClient::InvalidResponseError, /non-JSON/)
    end
  end

  describe "authentication headers" do
    let(:pool) { client.instance_variable_get(:@pool) }
    let(:secret) { "test-secret-key-at-least-32-characters-long" }

    around do |example|
      original = ENV.fetch("MAMPFSEARCH_API_SECRET", nil)
      ENV["MAMPFSEARCH_API_SECRET"] = secret
      example.run
    ensure
      ENV["MAMPFSEARCH_API_SECRET"] = original
    end

    def fake_response(code, body)
      status = double("status", code: code)
      double("response", status: status, body: double("body", to_s: body))
    end

    it "attaches Authorization header with /lesson/ingest scope for transcribe_lesson" do
      fake_http = double("http")
      expect(fake_http).to receive(:headers) do |headers|
        auth = headers[:authorization]
        expect(auth).to start_with("Bearer ")
        token = auth.delete_prefix("Bearer ")
        payload = SearchApiToken.verify!(token, scope: "/lesson/ingest")
        expect(payload["scope"]).to eq("/lesson/ingest")
        fake_http
      end
      expect(fake_http).to receive(:post).with("/lesson/ingest", params: {
                                                 media_rails_id: 1,
                                                 course_rails_id: 3,
                                                 video_url: "http://video.url",
                                                 transcript_upload_url: "http://upload.url",
                                                 lecture_rails_id: 2
                                               }).and_return(fake_response(200,
                                                                           '{"status":"queued"}'))

      allow(pool).to receive(:with) { |&block| block.call(fake_http) }

      client.transcribe_lesson(
        media_rails_id: 1, lecture_rails_id: 2, course_rails_id: 3,
        video_url: "http://video.url", transcript_upload_url: "http://upload.url"
      )
    end

    it "attaches Authorization header with /lesson/media/:id scope for delete_media" do
      fake_http = double("http")
      expect(fake_http).to receive(:headers) do |headers|
        auth = headers[:authorization]
        expect(auth).to start_with("Bearer ")
        token = auth.delete_prefix("Bearer ")
        payload = SearchApiToken.verify!(token, scope: "/lesson/media/42")
        expect(payload["scope"]).to eq("/lesson/media/42")
        fake_http
      end
      expect(fake_http).to receive(:delete).with("/lesson/media/42")
                                           .and_return(
                                             fake_response(
                                               200,
                                               '{"status":"deleted","media_rails_id":42}'
                                             )
                                           )

      allow(pool).to receive(:with) { |&block| block.call(fake_http) }

      client.delete_media(42)
    end

    it "attaches Authorization header with /lesson/list scope for list_media_rails_ids" do
      fake_http = double("http")
      expect(fake_http).to receive(:headers) do |headers|
        auth = headers[:authorization]
        expect(auth).to start_with("Bearer ")
        token = auth.delete_prefix("Bearer ")
        payload = SearchApiToken.verify!(token, scope: "/lesson/list")
        expect(payload["scope"]).to eq("/lesson/list")
        fake_http
      end
      expect(fake_http).to receive(:post).with("/lesson/list")
                                         .and_return(fake_response(200,
                                                                   '{"media_rails_ids":[1,2,3]}'))

      allow(pool).to receive(:with) { |&block| block.call(fake_http) }

      expect(client.list_media_rails_ids).to eq([1, 2, 3])
    end

    it "does not attach Authorization header for health" do
      fake_http = double("http")
      expect(fake_http).not_to receive(:headers)
      expect(fake_http).to receive(:get).with("/ready")
                                        .and_return(fake_response(200, '{"status":"ok"}'))

      allow(pool).to receive(:with) { |&block| block.call(fake_http) }

      client.health
    end
  end

  describe "when not configured" do
    let(:unconfigured) { described_class.send(:new, base_url: "") }

    it "raises ServiceUnavailableError on a request instead of ArgumentError" do
      expect { unconfigured.health }
        .to raise_error(SearchClient::ServiceUnavailableError, /not configured/)
    end
  end
end
