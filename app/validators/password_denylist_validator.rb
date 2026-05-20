require "set"

class PasswordDenylistValidator < ActiveModel::EachValidator
  DENYLIST = Set.new(%w[
    123456789012
    123412341234
    abc123abc123
    admin12345
    adminadmin12
    asdfghjkl123
    changeme123
    iloveyou123
    letmein12345
    passwort1234
    password123
    password1234
    password12345
    password123456
    qwerty12345
    qwertyuiop12
    welcome12345
  ]).freeze

  def validate_each(record, attribute, value)
    return if value.blank?
    return unless DENYLIST.include?(normalize(value))

    record.errors.add(attribute, I18n.t("errors.messages.password_too_common"))
  end

  private

    def normalize(value)
      value.to_s.unicode_normalize(:nfkc).strip.downcase
    end
end