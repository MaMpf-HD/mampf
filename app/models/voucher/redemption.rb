# Redemptions store the event of a user redeeming a voucher.
#
# During one redemption of a voucher, a user might claim multiple objects, e.g.
# two tutorial slots. The respective claims are stored in the Claims model.
#
# Also provides class methods to find out about users who have redeemed
# specific vouchers, e.g. tutors by redemption in a given lecture.
class Redemption < ApplicationRecord
  belongs_to :voucher
  belongs_to :user
  has_many :claims, dependent: :destroy
  has_many :claimed_tutorials, through: :claims, source: :claimable,
                               source_type: Tutorial.name
  has_many :claimed_talks, through: :claims, source: :claimable,
                           source_type: Talk.name

  has_many :notifications, as: :notifiable, dependent: :destroy

  class << self
    def tutors_by_redemption_in(lecture)
      users_that_redeemed_vouchers(lecture.vouchers.for_tutors)
    end

    def editors_by_redemption_in(lecture)
      users_that_redeemed_vouchers(lecture.vouchers.for_editors)
    end

    def speakers_by_redemption_in(lecture)
      users_that_redeemed_vouchers(lecture.vouchers.for_speakers)
    end

    private

      # Returns the users who have redeemed the given vouchers.
      #
      # These users could be called "Redeemers", but note that this should not
      # be confused with the Redeemer module that is responsible for the redemption
      # process of a voucher.
      def users_that_redeemed_vouchers(relevant_vouchers)
        user_ids = Redemption.where(voucher: relevant_vouchers).pluck(:user_id)
        User.where(id: user_ids.uniq)
      end
  end
end
