# Takes the addresses of banned accounts out of every mail before it goes out,
# whichever mailer built it: MaMpf's own, Devise's, Thredded's or
# Commontator's. A mail left without any recipient is not sent.
#
# Defined here instead of under app/, so that the registered module survives a
# code reload; User is looked up at delivery.
module BannedRecipientsInterceptor
  FIELDS = [:to, :cc, :bcc].freeze

  def self.delivering_email(message)
    addresses = FIELDS.flat_map { |field| Array(message[field]&.addrs).map(&:address) }
    banned = User.banned_addresses(addresses)
    return if banned.empty?

    FIELDS.each do |field|
      next unless message[field]

      kept = message[field].addrs.reject { |addr| banned.include?(addr.address.downcase) }
      message[field] = kept.map(&:to_s).presence
    end
    message.perform_deliveries = false if FIELDS.none? { |field| message[field] }
  end
end

ActiveSupport.on_load(:action_mailer) do
  register_interceptor(BannedRecipientsInterceptor)
end
