class UploadScanResult
  attr_reader :status, :signature, :detail

  def self.clean
    new(status: :clean)
  end

  def self.infected(signature)
    new(status: :infected, signature: signature)
  end

  def self.unavailable(detail = nil)
    new(status: :unavailable, detail: detail)
  end

  def self.timeout
    new(status: :timeout)
  end

  def initialize(status:, signature: nil, detail: nil)
    @status = status
    @signature = signature
    @detail = detail
  end

  def clean?
    status == :clean
  end

  def infected?
    status == :infected
  end

  def unavailable?
    status == :unavailable
  end

  def timeout?
    status == :timeout
  end
end