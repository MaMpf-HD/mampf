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
end
