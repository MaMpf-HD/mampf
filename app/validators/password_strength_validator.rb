require "zxcvbn"

class PasswordStrengthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    user_inputs = [record.email, record.name].compact
    score = Zxcvbn.test(value, user_inputs).score

    return unless score < 3

    record.errors.add(attribute, I18n.t("errors.messages.password_too_weak"))
  end
end
