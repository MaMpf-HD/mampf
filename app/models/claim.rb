# Claim class
# claims store what is beign taken over by the user when they redeem a voucher
# (e.g. a tutorial or a talk)

class Claim < ApplicationRecord
  belongs_to :redemption
  belongs_to :claimable, polymorphic: true
end
