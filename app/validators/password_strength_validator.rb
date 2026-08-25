# Validates the strength of a password using the zxcvbn library.
require "zxcvbn"

class PasswordStrengthValidator < ActiveModel::EachValidator
  # Words zxcvbn must not count as entropy. Its Ruby port only carries English
  # dictionaries, so the German ones a Heidelberg student reaches for first are
  # listed here -- otherwise the server accepts what the meter in the browser,
  # which does load German, already warns about.
  LOCAL_IDENTIFIERS = ["mampf", "muesli", "heidelberg", "uni-heidelberg",
                       "mathi", "mathinf", "mathematische",
                       "medienplattform",
                       "passwort", "kennwort", "geheim",
                       "sommersemester", "wintersemester", "semester",
                       "vorlesung", "uebung", "übung", "klausur",
                       "mathematik", "informatik", "physik",
                       "student", "studentin", "studium", "universitaet",
                       "universität"].freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    user_inputs = [record.email, record.name, *LOCAL_IDENTIFIERS].compact
    score = Zxcvbn.test(value, user_inputs).score

    return unless score < 3

    record.errors.add(attribute, I18n.t("errors.messages.password_too_weak"))
  end
end
