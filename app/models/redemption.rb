# Redemption class
# redemptions store the event of a user redeeming a voucher

class Redemption < ApplicationRecord
  belongs_to :voucher
  belongs_to :user
  has_many :claims, dependent: :destroy
  has_many :claimed_tutorials, through: :claims, source: :claimable,
                               source_type: "Tutorial"
  has_many :claimed_talks, through: :claims, source: :claimable,
                           source_type: "Talk"

  delegate :lecture, to: :voucher
  delegate :sort, to: :voucher
  delegate :tutor?, to: :voucher
  delegate :editor?, to: :voucher
  delegate :teacher?, to: :voucher
  delegate :speaker?, to: :voucher
end
