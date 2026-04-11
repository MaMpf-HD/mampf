module TurboStreamFlashAssertions
  def assert_flash_error
    assert_turbo_stream(action: :prepend, target: "flash-messages")
    # alert-warning class produced by setting the flash type to :alert
    expect(response.body).to include("alert-warning")
  end
end

RSpec.configure do |config|
  config.include TurboStreamFlashAssertions, type: :request
end
