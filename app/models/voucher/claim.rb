# A Claim stores a Claimable that is being taken over by the user when they
# redeem a voucher. Claimables are tutorials.
class Claim < ApplicationRecord
  belongs_to :redemption
  belongs_to :claimable, polymorphic: true
end
