# Referrals Helper
module ReferralsHelper
  def teachable_selector(referral)
    return '' unless referral.medium.present?
    unless referral.item.present?
      return referral.medium.teachable.media_scope.class.to_s + '-' +
             referral.medium.teachable.media_scope.id.to_s
    end
    return 'external-0' if referral.item.sort == 'link'
    referral.item.medium.teachable.media_scope.class.to_s + '-' +
      referral.item.medium.teachable.media_scope.id.to_s
  end

  def show_link(referral)
    return true if referral.item.present? && referral.item.sort == 'link'
    false
  end

  def show_explanation(referral)
    return false if referral.item.nil?
    true
  end
end
