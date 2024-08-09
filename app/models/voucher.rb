class Voucher < ApplicationRecord
  SORT_HASH = { tutor: 0, editor: 1, teacher: 2 }.freeze

  enum sort: SORT_HASH

  belongs_to :lecture, touch: true
  before_create :generate_secure_hash
  before_create :add_expiration_datetime
  before_create :ensure_no_other_active_voucher
  validates :sort, presence: true

  scope :active, -> { where("expires_at > ?", Time.zone.now) }

  self.implicit_order_column = "created_at"

  def active?
    expires_at > Time.zone.now
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
      return unless lecture.vouchers.where(sort: sort).any?(&:active?)

      errors.add(:sort,
                 I18n.t("activerecord.errors.models.voucher.attributes.sort.only_one_active"))
      throw(:abort)
    end
end
