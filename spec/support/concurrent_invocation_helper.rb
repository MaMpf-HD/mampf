module ConcurrentInvocationHelper
  def run_concurrently(thread_count: 2)
    ready = Queue.new
    start = Queue.new
    results = Queue.new

    threads = Array.new(thread_count) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          results << yield
        rescue StandardError => e
          results << e
        end
      end
    end

    thread_count.times { ready.pop }
    thread_count.times { start << true }
    threads.each(&:join)

    Array.new(thread_count) { results.pop }
  end
end

RSpec.configure do |config|
  config.include ConcurrentInvocationHelper
end
