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
    { 'video' => item.video_link, 'manuscript' => item.manuscript_link,
      'link' => link, 'quiz' => item.quiz_link,
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
    if item.present? && item.video? && item.sort != 'pdf_destination'
      return true
    end
    false
  end

  def manuscript?
    return true if item.present? && item.manuscript?
    false
  end

  def quiz?
    return true if item.present? && item.quiz?
    false
  end

  def medium_link?
    return true if item.present? && item.medium_link?
    false
  end

  def item_published?
    return true unless item && item.medium
    item.medium.published?
  end

  def item_locked?
    return false unless item && item.medium
    item.medium.locked?
  end

  def item_in_quarantine?
    return false unless item && item.quarantine
    true
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
    return true if medium.nil?
    return true unless start_time.valid?
    return true if start_time.total_seconds <= medium.video_duration
    errors.add(:start_time, :too_late)
    false
  end

  def end_time_not_too_late
    return true if medium.nil?
    return true unless end_time.valid?
    return true if end_time.total_seconds <= medium.video_duration
    errors.add(:end_time, :too_late)
    false
  end

  def end_time_not_too_soon
    return true unless start_time.valid?
    return true unless end_time.valid?
    return true if start_time.total_seconds < end_time.total_seconds
    errors.add(:end_time, :too_soon)
    false
  end
end
