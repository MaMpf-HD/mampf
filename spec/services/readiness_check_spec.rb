require "rails_helper"

RSpec.describe(ReadinessCheck) do
  describe "#call" do
    subject(:call) { described_class.new.call }

    let(:cache_key) { "readiness:abc123" }

    before do
      allow(SecureRandom).to receive(:hex).and_return("abc123")
    end

    it "returns ok when all dependencies respond successfully" do
      connection = instance_double("ActiveRecord::Connection", select_value: 1)
      redis = instance_double("RedisConnection", ping: "PONG")

      allow(ActiveRecord::Base.connection_pool)
        .to receive(:with_connection).and_yield(connection)
      allow(Sidekiq).to receive(:redis).and_yield(redis)
      allow(Rails.cache).to receive(:write)
      allow(Rails.cache).to receive(:read).with(cache_key).and_return("ok")
      allow(Rails.cache).to receive(:delete).with(cache_key)

      expect(call).to eq(
        database: "ok",
        redis: "ok",
        memcached: "ok"
      )
    end

    it "marks the database as error when the connection cannot be checked" do
      allow(ActiveRecord::Base.connection_pool).to receive(:with_connection)
        .and_raise(ActiveRecord::ConnectionNotEstablished, "db unavailable")
      allow(Sidekiq).to receive(:redis).and_yield(instance_double("RedisConnection", ping: "PONG"))
      allow(Rails.cache).to receive(:write)
      allow(Rails.cache).to receive(:read).with(cache_key).and_return("ok")
      allow(Rails.cache).to receive(:delete).with(cache_key)

      expect(call).to eq(
        database: "error",
        redis: "ok",
        memcached: "ok"
      )
    end

    it "marks redis as error when the connection cannot be checked" do
      connection = instance_double("ActiveRecord::Connection", select_value: 1)
      redis_error_class = if defined?(RedisClient::CannotConnectError)
        RedisClient::CannotConnectError
      elsif defined?(Redis::CannotConnectError)
        Redis::CannotConnectError
      else
        StandardError
      end

      allow(ActiveRecord::Base.connection_pool)
        .to receive(:with_connection).and_yield(connection)
      allow(Sidekiq).to receive(:redis)
        .and_raise(redis_error_class, "redis unavailable")
      allow(Rails.cache).to receive(:write)
      allow(Rails.cache).to receive(:read).with(cache_key).and_return("ok")
      allow(Rails.cache).to receive(:delete).with(cache_key)

      expect(call).to eq(
        database: "ok",
        redis: "error",
        memcached: "ok"
      )
    end

    it "marks memcached as error when the cache cannot be checked" do
      connection = instance_double("ActiveRecord::Connection", select_value: 1)
      cache_error_class = if defined?(Dalli::NetworkError)
        Dalli::NetworkError
      else
        StandardError
      end

      allow(ActiveRecord::Base.connection_pool)
        .to receive(:with_connection).and_yield(connection)
      allow(Sidekiq).to receive(:redis).and_yield(instance_double("RedisConnection", ping: "PONG"))
      allow(Rails.cache).to receive(:write)
        .and_raise(cache_error_class, "memcached unavailable")
      allow(Rails.cache).to receive(:delete).with(cache_key)

      expect(call).to eq(
        database: "ok",
        redis: "ok",
        memcached: "error"
      )
    end
  end
end
