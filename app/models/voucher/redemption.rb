# Redemptions store the event of a user redeeming a voucher.
#
# During one redemption of a voucher, a user might claim multiple objects, e.g.
# two tutorial slots. The respective claims are stored in the Claims model.
class Redemption < ApplicationRecord
  belongs_to :voucher
  belongs_to :user
  has_many :claims, dependent: :destroy
  has_many :claimed_tutorials, through: :claims, source: :claimable,
                               source_type: Tutorial.name
  has_many :claimed_talks, through: :claims, source: :claimable,
                           source_type: Talk.name

  has_many :notifications, as: :notifiable, dependent: :destroy
end
