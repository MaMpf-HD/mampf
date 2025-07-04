# A voucher is a unique (secure) hash that can be used by users to redeem a role,
# such as tutor, teacher etc. That is, the voucher grants the user elevated
# permissions.
#
# Vouchers are created by lecture editors, e.g. teachers. They will then send
# the voucher to the user by means of a different communication channel,
# e.g. email. Users can redeem the voucher by entering the code on their
# profile page.
#
# Before the introduction of vouchers, teachers could select from the whole pool
# of MaMpf users to assign them a role, e.g. to select tutors for their lecture.
# To better align this process with GDPR requirements, the concept of voucher
# was introduced. This way, teachers can only assign roles to users who have
# actively redeemed a voucher.
class Voucher < ApplicationRecord
  include Redeemer

  SPEAKER_EXPIRATION_DAYS = 30
  TUTOR_EXPIRATION_DAYS = 14
  DEFAULT_EXPIRATION_DAYS = 3

  ROLE_HASH = { tutor: 0, editor: 1, teacher: 2, speaker: 3 }.freeze
  enum :role, ROLE_HASH
  validates :role, presence: true

  belongs_to :lecture, touch: true

  before_create :generate_secure_hash
  before_create :add_expiration_datetime
  before_create :ensure_no_other_active_voucher
  before_create :ensure_speaker_vouchers_only_for_seminars

  scope :active, lambda {
                   where("expires_at > ? AND invalidated_at IS NULL",
                         Time.zone.now)
                 }
  scope :for_tutors, -> { where(role: :tutor) }
  scope :for_editors, -> { where(role: :editor) }
  scope :for_speakers, -> { where(role: :speaker) }

  self.implicit_order_column = :created_at

  def self.roles_for_lecture(lecture)
    return ROLE_HASH.keys if lecture.seminar?

    ROLE_HASH.keys - [:speaker]
  end

  def self.find_voucher_by_hash(secure_hash)
    # strip() to avoid issues with leading/trailing whitespaces when copy-pasting
    Voucher.active.find_by(secure_hash: secure_hash.strip)
  end

  def invalidate!
    update(invalidated_at: Time.zone.now)
  end

  private

    def generate_secure_hash
      self.secure_hash = SecureRandom.hex(16)
    end

    def add_expiration_datetime
      self.expires_at = created_at + expiration_days.days
    end

    def ensure_no_other_active_voucher
      return unless lecture
      return unless lecture.vouchers.where(role: role).active.any?

      errors.add(:role,
                 I18n.t("activerecord.errors.models.voucher.attributes.role." \
                        "only_one_active"))
      throw(:abort)
    end

    def ensure_speaker_vouchers_only_for_seminars
      return unless speaker?
      return if lecture.seminar?

      errors.add(:role,
                 I18n.t("activerecord.errors.models.voucher.attributes.role." \
                        "speaker_vouchers_only_for_seminars"))
      throw(:abort)
    end

    def expiration_days
      return SPEAKER_EXPIRATION_DAYS if speaker?
      return TUTOR_EXPIRATION_DAYS if tutor?

      DEFAULT_EXPIRATION_DAYS
    end
end
