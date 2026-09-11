module Vignettes
  # A pseudonym under which answers are filed. It carries no user id on
  # purpose: the only thing tying a person to their answers is the code they
  # wrote down, which is what makes consent to the study revocable by them and
  # unreadable by us.
  class Codename < ApplicationRecord
    # No I, O, 0 or 1: the student copies this off the screen onto paper and
    # types it back weeks later, in another vignette. Twelve characters out of
    # these thirty-two are 60 bits, so nobody stumbles onto someone else's.
    ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ".freeze
    FOREIGN_CHARACTERS = /[^#{ALPHABET}]/
    LENGTH = 12
    GROUP_SIZE = 4

    has_many :user_answers,
             class_name: "Vignettes::UserAnswer",
             foreign_key: "vignettes_codename_id",
             dependent: :destroy,
             inverse_of: :codename

    validates :pseudonym, presence: true, uniqueness: true

    def self.generate!
      3.times do
        codename = new(pseudonym: random_pseudonym)
        return codename if codename.save
      end

      raise(ActiveRecord::RecordNotSaved, "no unique codename after three tries")
    end

    def self.random_pseudonym
      Array.new(LENGTH) { ALPHABET[SecureRandom.random_number(ALPHABET.length)] }.join
    end

    # Accepts what a student types back: any casing, and the dashes we showed
    # them. Returns nil if it cannot be a codename at all.
    def self.normalize(input)
      candidate = input.to_s.upcase.gsub(FOREIGN_CHARACTERS, "")
      return if candidate.length != LENGTH

      candidate
    end

    # An unknown but well-formed codename opens a new record rather than an
    # error: refusing it would tell the world which codenames exist.
    def self.claim(input)
      pseudonym = normalize(input)
      return unless pseudonym

      find_or_create_by(pseudonym: pseudonym)
    end

    def grouped
      pseudonym.scan(/.{1,#{GROUP_SIZE}}/o).join("-")
    end
  end
end
