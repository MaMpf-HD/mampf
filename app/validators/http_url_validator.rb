class HttpUrlValidator < ActiveModel::EachValidator
  # Refuses control characters and line breaks before parsing: the encoding
  # below would turn them into part of a valid URL.
  def self.compliant?(value)
    return false if value.match?(/[[:cntrl:]]|\R/)

    uri = URI.parse(Addressable::URI.encode(value))
    uri.is_a?(URI::HTTP) && !uri.host.nil?
  rescue URI::InvalidURIError
    false
  end

  def validate_each(record, attribute, value)
    return if value.present? && self.class.compliant?(value)

    record.errors.add(attribute, I18n.t("activerecord.errors.no_valid_url"))
  end
end
