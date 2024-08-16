class Voucher < ApplicationRecord
  SORT_HASH = { tutor: 0, editor: 1, teacher: 2 }.freeze

  enum sort: SORT_HASH

  belongs_to :lecture, touch: true
  before_create :generate_secure_hash
  has_many :redemptions, dependent: :destroy

  before_create :add_expiration_datetime
  before_create :ensure_no_other_active_voucher
  validates :sort, presence: true

  scope :active, lambda {
                   where("expires_at > ? AND invalidated_at IS NULL",
                         Time.zone.now)
                 }
  scope :for_tutors, -> { where(sort: :tutor) }
  scope :for_editors, -> { where(sort: :editor) }

  self.implicit_order_column = "created_at"

  def self.check_voucher(secure_hash)
    Voucher.active.find_by(secure_hash: secure_hash)
  end

  private

    def generate_secure_hash
      self.secure_hash = SecureRandom.hex(16)
    end

    def add_expiration_datetime
      self.expires_at = created_at + 90.days
    end

    def ensure_no_other_active_voucher
      return unless lecture
      return unless lecture.vouchers.where(sort: sort).active.any?

      errors.add(:sort,
                 I18n.t("activerecord.errors.models.voucher.attributes.sort.only_one_active"))
      throw(:abort)
    end
end
