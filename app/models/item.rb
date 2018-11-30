# ItemClass
# An Item corresponds to an entry in the table of contents of a video
# of certain type (theorem, remark, lemma,..) or is a wrapper around
# a link, a medium oder a pdf destination.
class Item < ApplicationRecord
  include ApplicationHelper

  # an item is usually associated to a section of a lecture
  belongs_to :section, optional: true

  # an item is usually associated to a medium
  belongs_to :medium, optional: true

  # an item can be referred to from media
  has_many :referrals, dependent: :destroy
  has_many :referring_media, through: :referrals, source: :medium

  # an item that corresponds to a toc entry of a video has a start time
  # start_time is a TimeStamp object (which is serialized for the db)
  serialize :start_time, TimeStamp

  # sort should be one of the following:
  # remark, ... , corollary - correspond to to toc entries of videos
  # link - corresponds to an external (hyper)link
  # pdf_destination - corresponds to a named destination in a pdf file
  #                   (these can be generated using the \hypertarget command of
  #                     the hyperref package of LaTex)
  # self - corresponds to items that are just wrappers around a medium
  validates :sort, inclusion: { in: ['remark', 'theorem', 'lemma', 'definition',
                                     'annotation', 'example', 'section',
                                     'algorithm', 'label', 'corollary',
                                     'link', 'pdf_destination', 'self'],
                                message: 'Unzulässiger Typ' }
  validates :link, http_url: true, if: :proper_link?
  validates :description,
            presence: { message: 'Beschreibung muss vorhanden sein.' },
            if: :link?
  validate :valid_start_time
  validate :start_time_not_too_late
  validate :no_duplicate_start_time
  validate :nonempty_link_or_explanation

  # media are cached in several places
  # items are touched in order to find out whether cache is out of date
  after_save :touch_medium
  before_destroy :touch_medium

  # returns one millisecond before the start time of the next item if there
  # is a next item, otherwise the end time of the video
  def end_time
    return unless video?
    return TimeStamp.new(total_seconds: medium.video_duration) if next_item.nil?
    TimeStamp.new(total_seconds: next_item.start_time.total_seconds - 0.001)
  end

  # returns the start and end time as a string that is used in the .vtt files
  # result might look like this:
  # "01:14:40.500 --> 01:19:42.249\n"
  def vtt_time_span
    start_time.vtt_string + ' --> ' + end_time.vtt_string + "\n"
  end

  # returns the description of the toc entry corresponding to this item
  # in the .vtt files
  # result might look like this:
  # "zu freien Moduln"
  def vtt_text
    return '' if sort == 'pdf_destination'
    return description if sort == 'link'
    short_description
  end

  # returns the reference of the toc entry corresponding to this item
  # in the .vtt files
  # result might look like this:
  # "Bem. 29.13: zu freien Moduln\n\n"
  def vtt_reference
    return short_description + "\n\n" unless short_reference.present?
    short_reference + ': ' + short_description + "\n\n"
  end

  # returns a reference to the item as it is used in .vtt files,
  # if the item is referred to from an given medium
  # result might look like this:
  # "Verweis auf LA 2 SS 17, Bem. 29.13:"
  def vtt_meta_reference(referring_medium)
    return 'externe Referenz:' if sort == 'link'
    ref = local?(referring_medium) ? short_reference : long_reference
    'Verweis auf ' + ref + ':'
  end

  # creates a reference as it would look like form *within* the given context
  # result might look like this:
  #  "Bem. 29.13"
  def short_reference
    return math_reference if math_items.include?(sort)
    toc_reference
  end

  # creates a reference as it would look like form *outside* the given context
  # result might look like this:
  #  "LA 2 SS 17, Bem. 29.13"
  def long_reference
    return short_reference if sort.in?(['self', 'link'])
    return short_ref_with_teachable if section.present?
    return medium.title_for_viewers unless short_reference.present?
    medium.title_for_viewers + ', ' + short_reference
  end

  # returns just the description, unless sort is section or self
  # result might look like this:   "zu freien Moduln"
  def short_description
    return section.title if sort == 'section' && section.present?
    return medium.title_for_viewers if sort == 'self'
    description.to_s
  end

  # unless the item is a link, pdf_destination or a wrap around a medium (self),
  # it returns the short reference together with a description
  # result might look like this:   "Bem. 29.13 zu freien Moduln"
  # in the other cases, it might look like that:
  # "KaViaR, Sitzung 27 vom 17.8.2017"  (self)
  #  "extern Spiegel" (link)
  #  "NÜSsE, Skript (pdf) # Nakayama-Lemma" (pdf_destination)
  def local_reference
    unless sort.in?(['self', 'link', 'pdf_destination'])
      return short_ref_with_description
    end
    local_non_math_reference
  end

  # returns the title of the item *within* a given course
  # Result might look like this:
  # "SS 17, Bem. 29.13 zu freien Moduln"
  def title_within_course
    return '' unless medium.present?
    return local_reference if medium.teachable_type == 'Course'
    medium.teachable.media_scope.term.to_label_short + ', ' + local_reference
  end

  # returns the title of the item *within* a given lecture
  # Result might look like this:
  # "Bem. 29.13 zu freien Moduln"
  def title_within_lecture
    local_reference
  end

  # returns whether the item lives within the context of the
  # given referring_medium
  # if the referring medium is associated to a lecture or a lesson,
  # this is true if the item belongs to a section of the lecture or the
  # lesson's lecture
  def local?(referring_medium)
    return false unless section.present?
    in?(referring_medium.teachable.lecture&.items)
  end

  # background color of different item sorts within thyme editor
  def background
    return '#0c0;' if ['remark', 'theorem', 'lemma', 'corollary',
                       'algorithm'].include?(sort)
    return '#1ad1ff;' if ['definition', 'annotation', 'example'].include?(sort)
    return 'lightgray;' if sort == 'link' || sort == 'self'
    ''
  end

  # special background for sections
  def section_background
    return 'beige;' if sort == 'section'
    'aliceblue;'
  end

  # if the associated medium contains a video, returns a link to the play
  # action, starting at the correct time
  # result might look like this:
  # "/media/22/play?time=4480.5"
  def video_link
    return if sort == 'pdf_destination'
    return unless video?
    return video_link_untimed if sort == 'self'
    video_link_timed
  end

  # if the associated medium contains a maanuscript, returns a link to the
  # pdf file, together with a page or a named destination if that exists
  # results might look like this:
  # "/uploads/store/medium/22/manuscript/original-0a49544a.pdf"
  # "/uploads/store/medium/22/manuscript/original-0a49544a.pdf#page=3"
  # "/uploads/store/medium/22/manuscript/original-0a49544a.pdf#big_theorem"
  def manuscript_link
    return unless manuscript?
    link = medium.manuscript[:original].url(host: host)
    return link + '#' + pdf_destination if pdf_destination.present?
    return link + '#page=' + page.to_s if page.present?
    link
  end

  # if the associated medium contains an external link, it is returned
  def medium_link
    return unless medium_link?
    medium.external_reference_link
  end

  def self.internal_sorts
    [['Definition', 'definition'], ['Bemerkung', 'remark'], ['Lemma', 'lemma'],
     ['Satz', 'theorem'], ['Beispiel', 'example'], ['Anmerkung', 'annotation'],
     ['Algorithmus', 'algorithm'], ['Folgerung', 'corollary'],
     ['Abschnitt', 'section'], ['Markierung', 'label']]
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
             'corollary' => 'Folg.', 'algorithm' => 'Alg.' }
    hash[sort]
  end

  # the next methods are used to put together the references and descriptions

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

  def non_math_reference
    return medium.title_for_viewers if sort == 'self'
    if sort == 'pdf_destination'
      return medium.title_for_viewers + ' (pdf) # ' + description
    end
    'extern ' + description.to_s if sort == 'link'
  end

  def local_non_math_reference
    return medium.local_title_for_viewers if sort == 'self'
    if sort == 'pdf_destination'
      return medium.local_title_for_viewers + ' (pdf) # ' + description
    end
    'extern ' + description.to_s if sort == 'link'
  end

  def short_ref_with_teachable
    unless short_reference.present?
      return medium.teachable.lecture.title_for_viewers
    end
    medium.teachable.lecture.title_for_viewers + ', ' + short_reference
  end

  def short_ref_with_description
    return short_reference + ' ' + description.to_s unless sort == 'section'
    short_ref_for_sections
  end

  def short_ref_for_sections
    return short_reference + ' ' + description if description.present?
    return short_reference + ' ' + section.title if section.present?
    short_reference
  end

  # the next two methods get video links using helper methods

  def video_link_untimed
    Rails.application.routes.url_helpers.play_medium_path(medium.id)
  end

  def video_link_timed
    Rails.application.routes.url_helpers
         .play_medium_path(medium.id, time: start_time.total_seconds)
  end

  # the next methods are used for validations

  def valid_start_time
    return true if start_time.nil?
    return true if start_time.valid?
    errors.add(:start_time, 'Ungültiges Zeitformat.')
    false
  end

  def start_time_not_required
    medium.nil? || sort == 'self' || sort == 'pdf_destination' ||
      !start_time.valid?
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

  # is used for after save and before destroy callbacks
  def touch_medium
    return unless medium.present? && medium.persisted?
    medium.touch
  end
end
