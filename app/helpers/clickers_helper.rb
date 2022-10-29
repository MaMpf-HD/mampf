# Clickers Helper
module ClickersHelper
  def generate_qr(text)
    require 'barby'
    require 'barby/barcode'
    require 'barby/barcode/qr_code'
    require 'barby/outputter/png_outputter'

    qrcode = Barby::QrCode.new(text, level: :h, size: 8)
    base64_output = Base64.encode64(qrcode.to_png({ xdim: 8 }))
    "data:image/png;base64,#{base64_output}"
  end
end