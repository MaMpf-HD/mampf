# Validates the strength of a password using the zxcvbn library.
require "zxcvbn"

class PasswordStrengthValidator < ActiveModel::EachValidator
  # zxcvbn only knows English dictionaries, so German words that are obvious
  # around here would count as strong unless they are listed.
  LOCAL_IDENTIFIERS = ["mampf", "muesli", "heidelberg", "uni-heidelberg",
                       "mathi", "mathinf", "mathematische",
                       "medienplattform",
                       "passwort", "kennwort", "geheim",
                       "sommersemester", "wintersemester", "semester",
                       "vorlesung", "uebung", "übung", "klausur",
                       "mathematik", "informatik", "physik",
                       "student", "studentin", "studium", "universitaet",
                       "universität"].freeze

  TESTER_LOCK = Mutex.new

  # `Zxcvbn.test` reads and ranks its dictionaries anew on every call, which
  # takes longer than the rest of a sign-up. A tester keeps them in memory and
  # only reads them, so the threads of a process can share one. Threads that
  # ask while the first one builds it wait instead of building their own.
  def self.tester
    @tester || TESTER_LOCK.synchronize { @tester ||= Zxcvbn::Tester.new }
  end

  def validate_each(record, attribute, value)
    return if value.blank?

    user_inputs = [record.email, record.name, *LOCAL_IDENTIFIERS].compact
    score = self.class.tester.test(value, user_inputs).score

    return unless score < 3

    record.errors.add(attribute, I18n.t("errors.messages.password_too_weak"))
  end
end
