class Item < ApplicationRecord
  include ApplicationHelper
  belongs_to :section, optional: true
  belongs_to :medium, optional: true
  has_many :referrals, dependent: :destroy
  has_many :referring_media, through: :referrals, source: :medium
  serialize :start_time, TimeStamp

  validates :sort, inclusion: { in: ['remark', 'theorem', 'lemma', 'definition',
                                     'annotation', 'example', 'section',
                                     'algorithm', 'self', 'link', 'corollary',
                                     'label', 'pdf_destination'],
                                message: 'Unzulässiger Typ' }
  validates :link, http_url: true, if: :proper_link?
  validates :description,
            presence: { message: 'Beschreibung muss vorhanden sein.' },
            if: :link?
  validate :valid_start_time
  validate :start_time_not_too_late
  validate :no_duplicate_start_time
  validate :nonempty_link_or_explanation
  after_save :touch_medium
  before_destroy :touch_medium

  def end_time
    return unless video?
    return TimeStamp.new(total_seconds: medium.video_duration) if next_item.nil?
    TimeStamp.new(total_seconds: next_item.start_time.total_seconds - 0.001)
  end

  def vtt_time_span
    start_time.vtt_string + ' --> ' + end_time.vtt_string + "\n"
  end

  def short_reference
    return math_reference if math_items.include?(sort)
    toc_reference
  end

  def long_reference
    unless sort.in?(['self', 'link'])
      if section.present?
        return medium.teachable.lecture.title_for_viewers unless short_reference.present?
        return medium.teachable.lecture.title_for_viewers + ', ' + short_reference
      end
      return medium.title_for_viewers unless short_reference.present?
      return medium.title_for_viewers + ', ' + short_reference
    end
    short_reference
  end

  def short_description
    return section.title if sort == 'section' && section.present?
    return medium.title_for_viewers if sort == 'self'
    description.to_s
  end

  def local_reference
    unless sort.in?(['self','link', 'pdf_destination'])
      return short_reference + ' ' + description.to_s unless sort == 'section'
      return short_reference + ' ' + description if description.present?
      return short_reference + ' ' + section.title if section.present?
      return short_reference
    end
    local_non_math_reference
  end

  def title_within_course
    return '' unless medium.present?
    return local_reference if medium.teachable.class.to_s == 'Course'
    medium.teachable.media_scope.term.to_label_short + ', ' + local_reference
  end

  def title_within_lecture
    local_reference
  end

  def local?(referring_medium)
    return false unless section.present?
    self.in?(referring_medium.teachable.lecture&.items)
  end

  def vtt_text
    return '' if sort == 'pdf_destination'
    return description if sort == 'link'
    short_description
  end

  def vtt_reference
    return short_description + "\n\n" unless short_reference.present?
    short_reference + ': ' + short_description + "\n\n"
  end

  def vtt_meta_reference(referring_medium)
    return 'externe Referenz:' if sort == 'link'
    ref = local?(referring_medium) ? short_reference : long_reference
    'Verweis auf ' + ref + ':'
  end

  def background
    return '#0c0;' if ['remark', 'theorem', 'lemma', 'corollary', 'algorithm'].include?(sort)
    return '#1ad1ff;' if ['definition', 'annotation', 'example'].include?(sort)
    return 'lightgray;' if sort == 'link' || sort == 'self'
    ''
  end

  def video_link
    return if sort == 'pdf_destination'
    return unless video?
    return video_link_untimed if sort == 'self'
    video_link_timed
  end

  def manuscript_link
    return unless manuscript?
    link = medium.manuscript[:original].url(host: host)
    return link + '#' + pdf_destination if pdf_destination.present?
    return link + '#page=' + page.to_s if page.present?
    link
  end

  def medium_link
    return unless medium_link?
    medium.external_reference_link
  end

  def self.internal_sorts
    [['Definition', 'definition'], ['Bemerkung', 'remark'], ['Lemma', 'lemma'],
     ['Satz', 'theorem'], ['Beispiel', 'example'], ['Anmerkung', 'annotation'],
     ['Algorithmus', 'algorithm'], ['Folgerung', 'corollary'], ['Abschnitt', 'section'],
     ['Markierung', 'label']]
  end

  def self.list
    Item.all.select { |i| i.medium.present? || i.sort == 'link' }
        .map { |i| [i.short_reference + ' ' + i.short_description, i.id] }
  end

  def video?
    medium.present? && medium.video.present?
  end

  def manuscript?
    medium.present? && medium.manuscript.present?
  end

  def medium_link?
    medium.present? && medium.external_reference_link.present?
  end

  def link?
    sort == 'link'
  end

  private

  def math_items
    ['remark', 'theorem', 'lemma', 'definition', 'annotation', 'example',
     'corollary', 'algorithm']
  end

  def other_items
    ['section', 'self', 'link', 'label', 'pdf_destination']
  end

  def proper_link?
    sort == 'link' && link.present?
  end

  def next_item
    medium.proper_items_by_time.find do |i|
      i.start_time.total_seconds > start_time.total_seconds
    end
  end

  def sort_long
    hash = { 'definition' => 'Def.', 'theorem' => 'Satz', 'remark' => 'Bem.',
             'lemma' => 'Lemma', 'annotation' => 'Anm.', 'example' => 'Bsp.',
             'corollary' => 'Folgerung', 'algorithm' => 'Alg.'}
    hash[sort]
  end

  def math_item_number
    ref_number.to_s
  end

  def math_reference
    sort_long + ' ' + math_item_number
  end

  def special_reference
    return 'Medium' if sort == 'self'
    return '' if sort == 'pdf_destination'
    'extern'
  end

  def section_reference
    return section.displayed_number.to_s if section.present?
    return '§' + ref_number if ref_number.present?
    ''
  end

  def toc_reference
    return section_reference if sort == 'section'
    return '' if sort == 'label'
    special_reference
  end

  def video_link_untimed
    Rails.application.routes.url_helpers.play_medium_path(medium.id)
  end

  def video_link_timed
    Rails.application.routes.url_helpers
         .play_medium_path(medium.id, time: start_time.total_seconds)
  end

  def valid_start_time
    return true if start_time.nil?
    return true if start_time.valid?
    errors.add(:start_time, 'Ungültiges Zeitformat.')
    false
  end

  def start_time_not_required
    medium.nil? || sort == 'self' || sort == 'pdf_destination' || !start_time.valid?
  end

  def start_time_not_too_late
    return true if start_time_not_required
    return true if start_time.total_seconds <= medium.video.metadata['duration']
    errors.add(:start_time, 'Startzeit darf nicht größer sein als Videolänge.')
    false
  end

  def start_times_without
    (medium.proper_items - [self]).map do |i|
      [i.start_time.floor_seconds, i.start_time.milliseconds]
    end
  end

  def no_duplicate_start_time
    return true if start_time_not_required
    if start_times_without.include?([start_time.floor_seconds,
                                     start_time.milliseconds])
      errors.add(:start_time,
                 'Für diese Startzeit gibt es bereits einen Eintrag.')
      false
    end
    true
  end

  def nonempty_link_or_explanation
    return true if sort != 'link'
    return true if link.present?
    return true if explanation.present?
    errors.add(:link,
               'Link und Erläuterung können nicht gleichzeitig leer sein.')
    errors.add(:explanation,
               'Link und Erläuterung können nicht gleichzeitig leer sein.')
  end

  def non_math_reference
    return medium.title_for_viewers if sort == 'self'
    return medium.title_for_viewers + ' (pdf) # ' + description if sort == 'pdf_destination'
    'extern ' + description.to_s if sort == 'link'
  end

  def local_non_math_reference
    return medium.local_title_for_viewers if sort == 'self'
    return medium.local_title_for_viewers + ' (pdf) # ' + description if sort == 'pdf_destination'
    'extern ' + description.to_s if sort == 'link'
  end

  def touch_medium
    return unless medium.present? && medium.persisted?
    medium.touch
  end
end
