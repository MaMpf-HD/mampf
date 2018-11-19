# Medium class
class Medium < ApplicationRecord
  include ApplicationHelper

  # a teachable is a course/lecture/lesson
  belongs_to :teachable, polymorphic: true

  # a medium has many tags
  has_many :medium_tag_joins, dependent: :destroy
  has_many :tags, through: :medium_tag_joins

  # linked media are media that are (in some way) related to this medium
  has_many :links, dependent: :destroy
  has_many :linked_media, through: :links

  # an editor is a user that is responsible for this medium and has the right to
  # change its content.
  # other users may have editing rights by inheritance (e.g., a course editor
  # has editing rights for all media related this course and lectures and
  # lessons associated with it), but those need not be listed here
  has_many :editable_user_joins, as: :editable, dependent: :destroy
  has_many :editors, through: :editable_user_joins, as: :editable,
                     source: :user

  # an item in this context can be
  # - an entry in the table of contents of the video
  # - a named destination in the manuscript
  # - a wrapper around this medium itself
  has_many :items, dependent: :destroy

  # referenced items are items that are referenced from within the video
  # a referenced item can be
  # - any item associated to another medium
  # - an external hyperlink
  has_many :referrals, dependent: :destroy
  has_many :referenced_items, through: :referrals, source: :item

  # include uploaders to realize video/manuscript/screenshot upload
  # this makes use of the shrine gem
  include VideoUploader[:video]
  include ImageUploader[:screenshot]
  include PdfUploader[:manuscript]

  # if an external reference is given, checkif it is (at least syntactically)
  # a valid http(s) adress
  validates :external_reference_link, http_url: true,
                                      if: :external_reference_link?
  # the other validations are pretty straightforward
  validates :sort, presence: { message: 'Es muss ein Typ angegeben werden.' }
  validates :teachable, presence: { message: 'Es muss eine Assoziation ' \
                                             'angegeben werden.' }
  validates :description, presence: { message: 'Es muss eine Beschreibung' \
                                               'angegeben werden.' },
                          unless: :undescribable?
  validates :editors, presence: { message: 'Es muss ein Editor ' \
                                           'angegeben werden.' }

  # some information about media are cached
  # to find out whether the cache is out of date, always touch'em after saving
  after_save :touch_teachable

  # after creation, this creates an item of type 'self' that is just a wrapper
  # around this medium, so the medium itself can be referenced from other media
  # as an item as well
  after_create :create_self_item

  # these are all the sorts of food(=projects) we currently serve
  def self.sort_enum
    %w[Kaviar Erdbeere Sesam Kiwi Reste KeksQuestion KeksQuiz]
  end

  # returns the array of all media subject to the conditions
  # provided by the params hash (keys: :course_id, :lecture_id, :project)
  # and the user's primary lecture for the given course (this is relevant for
  # the ordering of the results as results for the primary lecture are placed
  # before hits for other lectures)
  def self.search(primary_lecture, params)
    course = Course.find_by_id(params[:course_id])
    return [] if course.nil?
    filtered = Medium.filter_media(course, params[:project])
    unless params[:lecture_id].present?
      return search_results(filtered, course, primary_lecture)
    end
    lecture = Lecture.find_by_id(params[:lecture_id].to_i)
    return [] unless course.lectures.include?(lecture)
    lecture.lecture_lesson_results(filtered)
  end

  # returns the ARel of all media for the given course and project
  def self.filter_media(course, project)
    return Medium.order(:id) unless project.present?
    return [] unless course.available_food.include?(project)
    sort = project == 'keks' ? 'KeksQuiz' : project.capitalize
    Medium.where(sort: sort).order(:id)
  end

  # returns the array of all media out of the given media that are associated
  # to a given course (with inheritance), with ordering
  # (depending on the given primary lecture) as described a few lines below
  def self.search_results(filtered_media, course, primary_lecture)
    course_results = filtered_media.select { |m| m.teachable == course }
    # media associated to primary lecture and its lessons
    primary_results = Medium.filter_primary(filtered_media, primary_lecture)
    # media associated to the course, all of its lectures and their lessons
    secondary_results = Medium.filter_secondary(filtered_media, course)
    # throw out media that have appeared as one of the above two types
    secondary_results = secondary_results - course_results - primary_results
    # differentiate primary results whether they are associated to the lecture
    # or a lesson of it
    primary_lecture_results = Medium.filter_by_lecture(primary_results)
    primary_lessons_results = primary_results - primary_lecture_results
    # sort them in the following way
    # - course results, by caption
    # - primary lecture results, by caption
    # - primary lesson results, by date
    # - secondary results
    course_results.natural_sort_by(&:caption) +
      primary_lecture_results.natural_sort_by(&:caption) +
      primary_lessons_results.sort_by { |m| m.teachable.date } +
      secondary_results
  end

  # returns the array of all media out of th egiven media who are associated
  # to a lecture
  def self.filter_by_lecture(media)
    media.select { |m| m.teachable_type == 'Lecture' }
  end

  # returns the array of all media out of the given media that are associated
  # to a given lecture and its lessons
  def self.filter_primary(filtered_media, primary_lecture)
    return [] unless primary_lecture.present?
    filtered_media.select do |m|
      m.teachable.present? && m.teachable.lecture == primary_lecture
    end
  end

  # returns the array of all media out of the given media that are associated
  # to a given course, its lectures their lessons
  def self.filter_secondary(filtered_media, course)
    filtered_media.select do |m|
      m.teachable.present? && m.teachable.course == course
    end
  end

  # returns the array of all media (by title), together with their ids
  # is used in options_for_select in form helpers.
  def self.select_by_name
    Medium.includes(:teachable).all.map { |m| [m.title, m.id] }
  end

  # protected items are items of type 'pdf_destination' inside associated to
  # this medium that are referred to from other media or from an entry
  # within the table of contents of the video associated to this medium.
  # they will not get auto-deleted when an attached pdf is removed, only if
  # the user insists (this way they are protected for example in the situation
  # where the user temporarily commented out some part of the manuscript)
  def protected_items
    pdf_items = Item.where(medium: self, sort: 'pdf_destination')
    referred_items = Referral.where(item: pdf_items).map(&:item)
    referencing_items = proper_items.select do |i|
      i.pdf_destination.in?(pdf_items.map(&:pdf_destination))
    end
    destination_items = Item.where(medium: self, sort: 'pdf_destination',
                                   pdf_destination: referencing_items
                                                      .map(&:pdf_destination))
    (referred_items + destination_items).to_a.uniq
  end

  # create items of type 'pdf_destination' out of the extracted named
  # destinations of the manuscript
  def create_pdf_destinations!
    manuscript_destinations.each do |d|
      next if Item.exists?(medium: self, sort: 'pdf_destination',
                           description: d, pdf_destination: d)
      Item.create(medium: self, sort: 'pdf_destination', description: d,
                  pdf_destination: d)
    end
  end

  # update the items of type 'pdf_destination' associated to this medium:
  # - destroy those that do no longer appear in the pdf's metadata,
  #   but preserve the protected items
  # - create new items for new destination entries in the pdf's metadata
  def update_pdf_destinations!
    items_to_conserve = protected_items
    create_pdf_destinations!
    items_to_destroy = Item.where(medium: self, sort: 'pdf_destination')
                           .reject do |i|
      i.pdf_destination.in?(manuscript_destinations) ||
        i.in?(items_to_conserve)
    end
    items_to_destroy.each(&:destroy)
  end

  # destroy all items of type 'pdf_destination' associated to this medium
  # (even protected ones) and remove all references to the corresponding
  # pdf_destinations from this medium's associated toc entries
  def destroy_pdf_destinations!(destinations)
    Item.where(medium: self, sort: 'pdf_destination',
               pdf_destination: destinations).each(&:destroy)
    proper_items.where(pdf_destination: destinations)
                .each do |i|
      i.update(pdf_destination: nil)
    end
  end

  # is the given user an editor of this medium?
  def edited_by?(user)
    return true if editors.include?(user)
    false
  end

  # returns true if the given user is an editor of this medium or
  # has editing rights by inheritance (e.g. if he is an editor of the
  # medium's associated teachable)
  def edited_with_inheritance_by?(user)
    return true if editors.include?(user)
    return true if teachable.lecture&.editors&.include?(user)
    return true if teachable.course.editors&.include?(user)
    false
  end

  def toc_to_vtt
    path = toc_path
    File.open(path, 'w+:UTF-8') do |f|
      f.write vtt_start
      proper_items_by_time.each do |i|
        f.write i.vtt_time_span
        f.write i.vtt_reference
      end
    end
    path
  end

  def references_to_vtt
    path = references_path
    File.open(path, 'w+:UTF-8') do |f|
      f.write vtt_start
      referrals_by_time.each do |r|
        f.write r.vtt_time_span
        f.write JSON.pretty_generate(r.vtt_properties) + "\n\n"
      end
    end
    path
  end

  def proper_items
    items.where.not(sort: ['self', 'pdf_destination'])
  end

  def proper_items_by_time
    proper_items.to_a.sort do |i, j|
      i.start_time.total_seconds <=> j.start_time.total_seconds
    end
  end

  def referrals_by_time
    referrals.to_a.sort do |r, s|
      r.start_time.total_seconds <=> s.start_time.total_seconds
    end
  end

  def manuscript_pages
    return unless manuscript.present?
    manuscript[:original].metadata['pages']
  end

  def screenshot_url
    return unless screenshot.present?
    screenshot.url(host: host)
  end

  def video_url
    return unless video.present?
    video.url(host: host)
  end

  def video_download_url
    video.url(host: download_host)
  end

  def video_filename
    return unless video.present?
    video.metadata['filename']
  end

  def video_size
    return unless video.present?
    video.metadata['size']
  end

  def video_resolution
    return unless video.present?
    video.metadata['resolution']
  end

  def video_duration
    return unless video.present?
    video.metadata['duration']
  end

  def video_duration_hms_string
    return unless video.present?
    TimeStamp.new(total_seconds: video_duration).hms_string
  end

  def manuscript_url
    return unless manuscript.present?
    manuscript[:original].url(host: host)
  end

  def manuscript_download_url
    manuscript[:original].url(host: download_host)
  end

  def manuscript_filename
    return unless manuscript.present?
    manuscript[:original].metadata['filename']
  end

  def manuscript_size
    return unless manuscript.present?
    manuscript[:original].metadata['size']
  end

  def manuscript_screenshot_url
    return unless manuscript.present?
    manuscript[:screenshot].url(host: host)
  end

  def manuscript_destinations
    return [] unless manuscript.present?
    if manuscript.class.to_s == 'PdfUploader::UploadedFile'
      return manuscript.metadata['destinations'] || []
    end
    return [] unless manuscript.class.to_s == 'Hash' &&
                     manuscript.keys == [:original, :screenshot]
    manuscript[:original].metadata['destinations'] || []
  end

  def video_width
    return unless video.present?
    video_resolution.split('x')[0].to_i
  end

  def video_height
    return unless video.present?
    video_resolution.split('x')[1].to_i
  end

  def video_aspect_ratio
    return unless video_height != 0 && video_width != 0
    video_width.to_f / video_height
  end

  def video_scaled_height(new_width)
    return unless video_height != 0 && video_width != 0
    (new_width.to_f / video_aspect_ratio).to_i
  end

  def caption
    return description if description.present?
    return '' unless sort == 'Kaviar' && teachable_type == 'Lesson'
    teachable.section_titles || ''
  end

  def card_header
    teachable.card_header
  end

  def card_header_teachable_path(user)
    teachable.card_header_path(user)
  end

  def card_subheader
    sort_de
  end

  def sort_de
    { 'Kaviar' => 'KaViaR', 'Sesam' => 'SeSAM',
      'KeksQuestion' => 'Keks-Frage', 'KeksQuiz' => 'Keks-Quiz',
      'Reste' => 'RestE', 'Erdbeere' => 'ErDBeere', 'Kiwi' => 'KIWi' }[sort]
  end

  def related_to_lecture?(lecture)
    return true if belongs_to_course?(lecture)
    return true if belongs_to_lecture?(lecture)
    return true if belongs_to_lesson?(lecture)
    false
  end

  def related_to_lectures?(lectures)
    lectures.map { |l| related_to_lecture?(l) }.include?(true)
  end

  def course
    return if teachable.nil?
    teachable.course
  end

  def lecture
    return if teachable.nil?
    teachable.lecture
  end

  def lesson
    return if teachable.nil?
    teachable.lesson
  end

  def irrelevant?
    video.nil? && manuscript.nil? && external_reference_link.blank?
  end

  def teachable_select
    teachable_type + '-' + teachable_id.to_s
  end

  def question_id
    return unless sort == 'KeksQuestion'
    external_reference_link.remove(DefaultSetting::KEKS_QUESTION_LINK).to_i
  end

  def question_ids
    return unless sort == 'KeksQuiz'
    external_reference_link.remove(DefaultSetting::KEKS_QUESTION_LINK)
                           .split(',').map(&:to_i)
  end

  def position
    teachable.media.where(sort: sort).order(:id).index(self) + 1
  end

  def siblings
    teachable.media.where(sort: sort)
  end

  def compact_info
    compact_info = sort_de + '.' + teachable.compact_title
    return compact_info unless siblings.count > 1
    compact_info + '.(' + position.to_s + '/' + siblings.count.to_s + ')'
  end

  def local_info
    return description if description.present?
    return 'ohne Titel' unless undescribable?
    if sort == 'Kaviar'
      return "zu Sitzung #{teachable.lesson&.number}, " \
             "#{teachable.lesson&.date_de}"
    end
    'KeksFrage ' + position.to_s + '/' + siblings.count.to_s
  end

  def details
    return description if description.present?
    return 'Frage ' + question_id.to_s if sort == 'KeksQuestion'
    return 'Fragen ' + question_ids.join(', ') if sort == 'KeksQuiz'
    ''
  end

  def title
    return compact_info if details.blank?
    compact_info + '.' + details
  end

  def title_for_viewers
    sort_de + ', ' + teachable.title_for_viewers +
      (description.present? ? ', ' + description : '')
  end

  def local_title_for_viewers
    if sort == 'Kaviar' && teachable.class.to_s == 'Lesson'
      return 'KaViaR, ' + teachable.local_title_for_viewers
    end
    sort_de + (description.present? ? ', ' + description : ', ohne Titel')
  end

  scope :KeksQuestion, -> { where(sort: 'KeksQuestion') }
  scope :Kaviar, -> { where(sort: 'Kaviar') }

  def items_with_references
    Rails.cache.fetch("#{cache_key}/items_with_reference") do
      items.map do |i|
        {
          id: i.id,
          title_within_course: i.title_within_course,
          title_within_lecture: i.title_within_lecture
        }
      end
    end
  end

  def reset_pdf_destinations
    Item.where(medium: self, sort: 'pdf_destination').each(&:destroy)
    manuscript_destinations.each do |d|
      Item.create(medium: self, sort: 'pdf_destination', description: d)
    end
  end

  private

  def undescribable?
    (sort == 'Kaviar' && teachable.class.to_s == 'Lesson') ||
      sort == 'KeksQuestion'
  end

  def touch_teachable
    return if teachable.nil?
    if teachable.course.present? && teachable.course.persisted?
      teachable.course.touch
    end
    optional_touches
  end

  def optional_touches
    if teachable.lecture.present? && teachable.lecture.persisted?
      teachable.lecture.touch
    end
    return unless teachable.lesson.present? && teachable.lesson.persisted?
    teachable.lesson.touch
  end

  def toc_path
    Rails.root.join('public', 'tmp').to_s + '/toc-' + SecureRandom.hex + '.vtt'
  end

  def references_path
    Rails.root.join('public', 'tmp').to_s + '/ref-' + SecureRandom.hex + '.vtt'
  end

  def vtt_start
    "WEBVTT\n\n"
  end

  def belongs_to_course?(lecture)
    teachable_type == 'Course' && teachable == lecture.course
  end

  def belongs_to_lecture?(lecture)
    teachable_type == 'Lecture' && teachable == lecture
  end

  def belongs_to_lesson?(lecture)
    teachable_type == 'Lesson' && teachable.lecture == lecture
  end

  def filter_primary(filtered_media, primary_lecture)
    filtered_media.select do |m|
      m.teachable.present? && m.teachable.lecture == primary_lecture
    end
  end

  def filter_secondary(filtered_media, course)
    filtered_media.select do |m|
      m.teachable.present? && m.teachable.course == course
    end
  end

  def create_self_item
    Item.create(sort: 'self', medium: self)
  end

  def local_items
    return teachable.items - items if teachable_type == 'Course'
    teachable.lecture.items - items
  end
end
