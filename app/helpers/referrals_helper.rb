# Referrals Helper
module ReferralsHelper
  # returns the referrable's medium's/item's teachable scope (if present)
  # in the form required by the teachable selector in the referral form,
  # e.g. as 'Lecture-42', 'Course-5' etc.
  def teachable_selector(referral)
    return '' unless referral.medium.present?
    unless referral.item.present?
      return referral.medium.teachable.media_scope.selector_value
    end
    return 'external-0' if referral.item.sort == 'link'
    referral.item.medium.teachable.media_scope.selector_value
  end

  def show_link(referral)
    return true if referral.item.present? && referral.item.sort == 'link'
    false
  end

  def show_explanation(referral)
    return false if referral.item.nil?
    true
  end

  # returns the color in which the rferral is presented in the refrences box
  # (pink if the item belongs to a non-released medium, white otherwise)
  def item_released_color(referral)
    referral.item_released? ? '' : 'bg-post-it-pink'
  end

  def item_status_color(referral)
    return 'bg-post-it-pink' if !referral.item_released?
    return 'bg-yellow-lighten-4' if referral.item_locked?
    ''
  end

  def item_released_color_value(referral)
    referral.item_released? ? 'white' : '#fad1df'
  end

  def item_status_color_value(referral)
    return '#fad1df' if !referral.item_released?
    return '#fff9c4' if referral.item_locked?
    'white'
  end
end
