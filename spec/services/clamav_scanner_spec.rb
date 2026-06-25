require "rails_helper"

# Captures everything written to the socket so we can assert exactly how many
# bytes were streamed to clamd over INSTREAM.
class FakeClamdSocket
  attr_reader :written

  def initialize(reply)
    @written = +"".b
    @reply = reply
  end

  def write(data)
    @written << data.b
    data.bytesize
  end

  def close_write
  end

  def read
    @reply
  end
end

RSpec.describe(ClamavScanner) do
  # Walks the INSTREAM payload (command, then <len><chunk> pairs, then a zero
  # terminator) and returns the total number of content bytes streamed.
  def streamed_bytes(written)
    body = written.b.dup
    body.slice!(0, "zINSTREAM\0".bytesize)
    total = 0
    until body.empty?
      length = body.slice!(0, 4).unpack1("N")
      break if length.zero?

      body.slice!(0, length)
      total += length
    end
    total
  end

  def run_scan(io, max_bytes:)
    socket = FakeClamdSocket.new("stream: OK\0")
    # Skip the test-env short circuit so the real streaming path runs.
    allow(Rails.env).to receive(:test?).and_return(false)
    allow(Socket).to receive(:tcp) { |*_args, &block| block.call(socket) }

    result = described_class.new.scan(io, max_bytes: max_bytes)
    [result, socket]
  end

  it "streams only the bounded prefix when the io is larger than max_bytes" do
    io = StringIO.new("a" * 100)

    result, socket = run_scan(io, max_bytes: 40)

    expect(streamed_bytes(socket.written)).to eq(40)
    expect(result).to be_clean
  end

  it "streams the whole io when it is smaller than max_bytes" do
    io = StringIO.new("a" * 20)

    _result, socket = run_scan(io, max_bytes: 40)

    expect(streamed_bytes(socket.written)).to eq(20)
  end

  it "streams the whole io when no bound is given" do
    io = StringIO.new("a" * 100)

    _result, socket = run_scan(io, max_bytes: nil)

    expect(streamed_bytes(socket.written)).to eq(100)
  end

  it "rewinds the io after a bounded scan" do
    io = StringIO.new("a" * 100)

    run_scan(io, max_bytes: 40)

    expect(io.pos).to eq(0)
  end

  it "reports infected results from the clamd reply" do
    socket = FakeClamdSocket.new("stream: Eicar-Test-Signature FOUND\0")
    allow(Rails.env).to receive(:test?).and_return(false)
    allow(Socket).to receive(:tcp) { |*_args, &block| block.call(socket) }

    result = described_class.new.scan(StringIO.new("a" * 100), max_bytes: 40)

    expect(result).to be_infected
    expect(result.signature).to eq("Eicar-Test-Signature")
  end
end
