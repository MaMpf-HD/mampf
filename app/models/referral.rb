# Referral class
# A referral describes a reference inside a medium (typically a video)
# to a certain item
class Referral < ApplicationRecord
  # a referral belongs to an item and a medium
  belongs_to :item
  belongs_to :medium

  # start_time and end_time are serialized columns
  serialize :start_time, TimeStamp
  serialize :end_time, TimeStamp

  # validations for start time and end time
  validate :valid_start_time
  validate :valid_end_time
  validate :start_time_not_too_late
  validate :end_time_not_too_late
  validate :end_time_not_too_soon

  # if the explanation column is nontrivial or no item is present
  # (e.g. for a new referral), return its value
  # otherwise, return the item's explanation
  def explain
    return explanation if item.nil?
    explanation || item.explanation
  end

  # provide time span for vtt file
  def vtt_time_span
    start_time.vtt_string + ' --> ' + end_time.vtt_string + "\n"
  end

  # provide metadata for vtt file
  def vtt_properties
    link = item.link.present? ? item.link : item.medium_link
    # at the moment, relations between items can be only of the form
    # script <-> video, which means that between them there will be at most
    # one script, one manuscript and one video
    if item.medium&.sort == 'Script'
      script = item.manuscript_link
      if item.related_items_visible?
        video = item.related_items&.first&.video_link
        manuscript = item.related_items&.first&.manuscript_link
      end
    else
      if item.related_items_visible?
        script = item.related_items&.first&.manuscript_link
      end
      manuscript = item.manuscript_link
      video = item.video_link
    end
    { 'video' => video, 'manuscript' => manuscript,
      'script' => script, 'link' => link, 'quiz' => item.quiz_link,
      'reference' => item.vtt_meta_reference(medium),
      'text' => item.vtt_text, 'explanation' => vtt_explanation }.compact
  end

  # returns whether this referral's item has been referred to
  # from other referrals
  def reappears
    item.present? && item.referrals.present? &&
      (item.referrals.map(&:id) - [id]).present?
  end

  # initial description in the referral form
  def prefilled_description
    item.present? ? item.description : ''
  end

  # initial link in the referral form
  def prefilled_link
    item.present? ? item.link : ''
  end

  # returns true iff the referral's item's medium has an associated video, but
  # the item is not a pdf destination
  def video?
    !!item&.video? && item.sort != 'pdf_destination'
  end

  def manuscript?
    !!item&.manuscript?
  end

  def quiz?
    !!item&.quiz?
  end

  def medium_link?
    !!item&.medium_link?
  end

  def item_published?
    !item&.medium || item.medium.published?
  end

  def item_locked?
    !!item&.medium&.locked?
  end

  def item_in_quarantine?
    !!item&.quarantine
  end

  private

  # explanation provided to the vtt file
  # returns the referral's explanation if present, the item's explanation
  # if the item is a link, otherwise nil
  def vtt_explanation
    return explanation if explanation.present?
    return item.explanation if item.sort == 'link' && item.explanation.present?
  end

  # some method that check for valid start and end time

  def valid_start_time
    return true if start_time.nil?
    return true if start_time.valid?
    errors.add(:start_time, :invalid_format)
    false
  end

  def valid_end_time
    return true if end_time.nil?
    return true if end_time.valid?
    errors.add(:end_time, :invalid_format)
    false
  end

  def start_time_not_too_late
    return true if medium.nil? || !medium.video
    return true unless start_time.valid?
    return true if start_time.total_seconds <= medium.video_duration
    errors.add(:start_time, :too_late)
    false
  end

  def end_time_not_too_late
    return true if medium.nil? || !medium.video
    return true unless end_time.valid?
    return true if end_time.total_seconds <= medium.video_duration
    errors.add(:end_time, :too_late)
    false
  end

  def end_time_not_too_soon
    return true unless start_time&.valid?
    return true unless end_time&.valid?
    return true if start_time.total_seconds < end_time.total_seconds
    errors.add(:end_time, :too_soon)
    false
  end
end
