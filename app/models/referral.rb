class Referral < ApplicationRecord
  belongs_to :item
  belongs_to :medium
  serialize :start_time, TimeStamp
  serialize :end_time, TimeStamp

  validate :valid_start_time
  validate :valid_end_time
  validate :start_time_not_too_late
  validate :end_time_not_too_late
  validate :end_time_not_too_soon
  validate :reference_present

  def explain
    return explanation if item.nil?
    explanation || item.explanation
  end

  def vtt_time_span
    start_time.vtt_string + ' --> ' + end_time.vtt_string + "\n"
  end

  def vtt_properties
    link = item.medium_link if medium_link
    link = item.link if item.link.present?
    manuscript_link = item.manuscript_link if manuscript
    video_link = item.video_link if video
    { 'video' => video_link, 'manuscript' => manuscript_link,
      'link' => link, 'reference' => item.vtt_meta_reference(medium),
      'text' => item.vtt_text, 'explanation' => vtt_explanation }.compact
  end

  def show_link
    return true if item.present? && item.sort == 'link'
    false
  end

  def show_explanation
    return false if item.nil?
    true
  end

  def reappears
    item.present? && item.referrals.present? &&
      (item.referrals.map(&:id) - [id]).present?
  end

  def prefilled_description
    item.present? ? item.description : ''
  end

  def prefilled_link
    item.present? ? item.link : ''
  end

  def video?
    return true if item.present? && item.video? && item.sort != 'pdf_destination'
    false
  end

  def manuscript?
    return true if item.present? && item.manuscript?
    false
  end

  def medium_link?
    return true if item.present? && item.medium_link?
    false
  end

  private

  def vtt_explanation
    return explanation if item.sort != 'link' && explanation.present?
    return item.explanation if item.sort == 'link' && item.explanation.present?
  end

  def valid_start_time
    return true if start_time.nil?
    return true if start_time.valid?
    errors.add(:start_time, 'Ungültiges Zeitformat.')
    false
  end

  def valid_end_time
    return true if end_time.nil?
    return true if end_time.valid?
    errors.add(:end_time, 'Ungültiges Zeitformat.')
    false
  end

  def start_time_not_too_late
    return true if medium.nil?
    return true unless start_time.valid?
    return true if start_time.total_seconds <= medium.video_duration
    errors.add(:start_time, 'Startzeit darf nicht größer sein als Videolänge.')
    false
  end

  def end_time_not_too_late
    return true if medium.nil?
    return true unless end_time.valid?
    return true if end_time.total_seconds <= medium.video_duration
    errors.add(:end_time, 'Endzeit darf nicht größer sein als Videolänge.')
    false
  end

  def end_time_not_too_soon
    return true unless start_time.valid?
    return true unless end_time.valid?
    return true if start_time.total_seconds < end_time.total_seconds
    errors.add(:end_time, 'Endzeit muss hinter der Startzeit liegen.')
    false
  end

  def reference_present
    return true if item.medium.nil?
    unless item.medium.video.present? || item.medium.manuscript.present? ||
           item.medium.external_reference_link.present?

      errors.add(:video, 'Das gewählte Medium kann nicht referenziert werden, '\
                         'da es keine Inhalte bereithält.')
      return false
    end
    return true if enough_references
    errors.add(:video, 'Es muss mindestens eine Referenz ausgewählt sein.')
  end

  def enough_references
    (item.medium.video.present? && video) ||
      (item.medium.manuscript.present? && manuscript) ||
      (item.medium.external_reference_link.present? && medium_link)
  end
end
