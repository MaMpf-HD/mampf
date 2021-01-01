# Medium class
class Medium < ApplicationRecord
  include ApplicationHelper
  include ActiveModel::Dirty

  # a teachable is a course/lecture/lesson
  belongs_to :teachable, polymorphic: true, optional: true
  acts_as_list scope: [:teachable_id, :teachable_type], top_of_list: 0

  # a teachable may belong to a quizzable (quiz/question/remark)
  belongs_to :quizzable, polymorphic: true, optional: true

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


  has_many :imports, dependent: :destroy
  has_many :importing_lectures, through: :imports,
           source: :teachable, source_type: 'Lecture'
  has_many :importing_courses, through: :imports,
           source: :teachable, source_type: 'Course'

  has_many :quiz_certificates, foreign_key: 'quiz_id', dependent: :destroy

  has_one :assignment

  serialize :quiz_graph, QuizGraph

  serialize :solution, Solution

  # include uploaders to realize video/manuscript/screenshot upload
  # this makes use of the shrine gem
  include VideoUploader[:video]
  include ScreenshotUploader[:screenshot]
  include PdfUploader[:manuscript]
  include GeogebraUploader[:geogebra]

  # if an external reference is given, check if it is (at least syntactically)
  # a valid http(s) adress
  validates :external_reference_link, http_url: true,
                                      if: :external_reference_link?

  # the other validations are pretty straightforward
  validates :sort, presence: true
  validates :teachable, presence: true, if: :proper?
  validates :description, presence: true, unless: :undescribable?
  validates :editors, presence: true, if: :proper?

  # make sure that a lecture cannot have two or more media of type 'Script'
  validate :at_most_one_manuscript
  # media of type 'Script' can only be associated to lectures
  validate :script_only_for_lectures
  # media of type 'Script' do not contain videos
  validate :no_video_for_script
  # media of type 'Script' shall not be changed to a different sort if they
  # contain nontrivial items, and other media shall not be changed to a Script
  validate :no_changing_sort_to_or_from_script
  # a medium of type Script is not allowed to have tags
  # (Reason: A typical script will have *a lot of* tags)
  validate :no_tags_for_scripts
  # if medium is associated to a nonpublished teachable, reset its published
  # property to nil
  before_save :reset_released_status
  # some information about media are cached
  # to find out whether the cache is out of date, always touch'em after saving
  after_save :touch_teachable

  # after creation, this creates an item of type 'self' that is just a wrapper
  # around this medium, so the medium itself can be referenced from other media
  # as an item as well
  after_create :create_self_item

  # if medium is a question or remark, delete all quiz vertices that refer to it
  before_destroy :delete_vertices

  # if medium is a question, delete all answers that belong to it
  after_destroy :delete_answers

  # keep track of copies (in particular for Questions, Remarks)
  acts_as_tree

  # media can be commented on
  acts_as_commontable dependent: :destroy

  # scope for published/locally visible media
  # locally visible media are published (without inheritance) and unlocked
  # (they may not be globally visible as their lecture may be unpublished)
  scope :published, -> { where.not(released: nil) }
  scope :locally_visible, -> { where(released: ['all', 'users']) }
  scope :potentially_visible, -> { where(released: ['all', 'users', 'subscribers']) }
  scope :proper, -> { where.not(sort: 'RandomQuiz') }
  scope :expired, -> { where(sort: 'RandomQuiz').where('created_at < ?', 1.day.ago) }

  searchable do
    text :description
    text :text do
      text_join
    end
    string :sort
    string :teachable_compact do
      "#{teachable_type}-#{teachable_id}"
    end
    string :release_state do
      release_state
    end
    boolean :clickerizable do
      clickerizable?
    end
    integer :id
    integer :teachable_id
    integer :tag_ids, multiple: true
    integer :editor_ids, multiple: true
    integer :answers_count
  end

  # these are all the sorts of food(=projects) we currently serve
  def self.sort_enum
    %w[Kaviar Erdbeere Sesam Kiwi Nuesse Script Question Quiz
       Reste Remark RandomQuiz]
  end

  # media sorts and their descriptions
  def self.sort_localized
    { 'Kaviar' => I18n.t('categories.kaviar.singular'),
      'Sesam' => I18n.t('categories.sesam.singular'),
      'Nuesse' => I18n.t('categories.exercises.singular'),
      'Script' => I18n.t('categories.script.singular'),
      'Kiwi' => I18n.t('categories.kiwi.singular'),
      'Quiz' => I18n.t('categories.quiz.singular'),
      'Question' => I18n.t('categories.question.singular'),
      'Remark' => I18n.t('categories.remark.singular'),
      'RandomQuiz' => I18n.t('categories.randomquiz.singular'),
      'Erdbeere' => I18n.t('categories.erdbeere.singular'),
      'Reste' => I18n.t('categories.reste.singular') }
  end

  # media sorts and their short descriptions
  def self.sort_localized_short
    { 'Kaviar' => I18n.t('categories.kaviar.short'),
      'Sesam' => I18n.t('categories.sesam.short'),
      'Nuesse' => I18n.t('categories.exercises.short'),
      'Script' => I18n.t('categories.script.short'),
      'Kiwi' => I18n.t('categories.kiwi.short'),
      'Quiz' => I18n.t('categories.quiz.short'),
      'Question' => I18n.t('categories.question.short'),
      'Remark' => I18n.t('categories.remark.short'),
      'RandomQuiz' => I18n.t('categories.randomquiz.short'),
      'Erdbeere' => I18n.t('categories.erdbeere.short'),
      'Reste' => I18n.t('categories.reste.short') }
  end


  def self.select_sorts
    Medium.sort_localized.except('RandomQuiz').map { |k, v| [v, k] }
  end

  def self.select_quizzables
    Medium.sort_localized.slice('Question', 'Remark').map { |k, v| [v, k] }
  end

  def self.select_importables
    Medium.sort_localized.except('RandomQuiz', 'Question', 'Remark',
                                 'Manuscript').map { |k, v| [v, k] }
  end

  def self.select_question
    Medium.sort_localized.slice('Question').map { |k, v| [v, k] }
  end

  # returns the array of all media subject to the conditions
  # provided by the params hash (keys: :id, :project)
  # :id represents the lecture id
  def self.search_all(params)
    lecture = Lecture.find_by_id(params[:id])
    return Medium.none if lecture.nil?
    media_in_project = Medium.media_in_project(params[:project])
    # media sitting at course level
    course_media_in_project = media_in_project.includes(:tags)
                                              .where(teachable: lecture.course)
                                              .order(boost: :desc,
                                                     description: :asc)
    # media sitting at lecture level
    # append results at course level to lecture/lesson level results
    lecture.lecture_lesson_results(media_in_project) + course_media_in_project
  end

  # returns the ARel of all media for the given project
  def self.media_in_project(project)
    return Medium.none unless project.present?
    sort = project == 'keks' ? 'Quiz' : project.capitalize
    Medium.where(sort: sort)
  end

  # returns the array of all media (by title), together with their ids
  # is used in options_for_select in form helpers.
  def self.select_by_name
    Medium.where.not(sort: ['Question', 'Remark', 'RandomQuiz'])
          .map { |m| [m.title_for_viewers, m.id] }
  end

  # returns the array of media sorts specified by the search params
  # search_params is a hash with keys :all_types, :types
  # value for :types is an array of integers which correspond to indices
  # in the sort_enum array
  def self.search_sorts(search_params)
    unless search_params[:all_types] == '0'
      return (Medium.sort_enum - ['RandomQuiz'])
    end
    search_params[:types] || []
  end

  # returns search results for the media search with search_params provided
  # by the controller
  def self.search_by(search_params, page)
    search_params[:types] = [] if search_params[:all_types] == '1'
    search_params[:teachable_ids] = TeachableParser.new(search_params)
                                                   .teachables_as_strings
    search_params[:editor_ids] = [] if search_params[:all_editors] == '1'
    if search_params[:all_tags] == '1' && search_params[:tag_operator] == 'and'
      search_params[:tag_ids] = Tag.pluck(:id)
    end
    search = Sunspot.new_search(Medium)
    search.build do
      with(:sort, search_params[:types])
      without(:sort, 'RandomQuiz')
      with(:editor_ids, search_params[:editor_ids])
      with(:teachable_compact, search_params[:teachable_ids])
    end
    if search_params[:purpose] == 'clicker'
      search.build do
        with(:clickerizable, true)
      end
    end
    unless search_params[:answers_count] == 'irrelevant'
      search.build do
        with(:answers_count, [-1, search_params[:answers_count].to_i])
      end
    end
    unless search_params[:access] == 'irrelevant'
      search.build do
        with(:release_state, search_params[:access])
      end
    end
    unless search_params[:all_tags] == '1' &&
             search_params[:tag_operator] == 'or'
      if search_params[:tag_ids]
        if search_params[:tag_operator] == 'or'
          search.build do
            with(:tag_ids).any_of(search_params[:tag_ids])
          end
        else
          search.build do
            with(:tag_ids).all_of(search_params[:tag_ids])
          end
        end
      else
        search.build do
          with(:tag_ids, nil)
        end
      end
    end
    if search_params[:fulltext].present?
      search.build do
        fulltext search_params[:fulltext] do
          boost_fields :description => 2.0
        end
      end
    end
    search.build do
      paginate page: page, per_page: search_params[:per]
    end
    search
  end

  def self.search_questions_by_tags(search_params)
    search = Sunspot.new_search(Medium)
    search.build do
      with(:sort, 'Question')
      with(:teachable_compact, search_params[:teachable_ids])
      with(:tag_ids).all_of(search_params[:tag_ids])
      paginate per_page: Question.count
    end
    search
  end

  def restricted?
    return false unless teachable
    teachable.restricted?
  end

  # protected items are items of type 'pdf_destination' inside associated to
  # this medium that are referred to from other media or from an entry
  # within the table of contents of the video associated to this medium.
  # they will not get auto-deleted when an attached pdf is removed, only if
  # the user insists (this way they are protected for example in the situation
  # where the user temporarily commented out some part of the manuscript)
  def protected_items
    return [] unless sort == 'Script'
    pdf_items = Item.where(medium: self).where.not(pdf_destination: nil)
    Referral.where(item: pdf_items).map(&:item).uniq
  end

  def vanished_items
    return [] unless sort == 'Script'
    Item.where(medium: self)
        .where.not(sort: 'self')
        .where.not(pdf_destination: manuscript_destinations)
  end

  def irrelevant_items
    Item.where(id: vanished_items.pluck(:id))
        .where.not(id: protected_items.pluck(:id))
  end

  # this is used by the controller for before/after comparison
  def missing_destinations
    protected_items.map(&:pdf_destination) - manuscript_destinations
  end

  def missing_items_outside_quarantine
    Item.where(medium: self, pdf_destination: missing_destinations)
        .unquarantined
  end

  def quarantine
    Item.where(medium: self, quarantine: true)
  end

  # update the items of type 'pdf_destination' associated to this medium:
  # - preserve only the protected items, destroy all others
  # - put items that correspond to missing destination in quarantine (and
  #   return these)
  def update_pdf_destinations!
    return unless sort == 'Script'
    irrelevant_items.delete_all
    result = missing_items_outside_quarantine.pluck(:pdf_destination)
    missing_items_outside_quarantine.update_all(quarantine: true)
    result
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
    return true if teachable&.lecture&.editors&.include?(user)
    return true if teachable&.lecture&.teacher == user
    return true if teachable&.course&.editors&.include?(user)
    false
  end

  def editors_with_inheritance
    (editors&.to_a + teachable.lecture&.editors.to_a +
      [teachable.lecture&.teacher] + teachable.course.editors.to_a).uniq.compact
  end


  # creates a .vtt tmp file (and returns it), which contains
  # all data needed by the thyme player to realize the toc
  def toc_to_vtt
    file = Tempfile.new(['toc-', '.vtt'], encoding: 'UTF-8')
    file.write vtt_start
    proper_items_by_time.reject(&:hidden).each do |i|
      file.write i.vtt_time_span
      file.write i.vtt_reference
    end
    file
  end

  # creates a .vtt file (and returns it), which contains
  # all data needed by the thyme player to realize references
  # Note: Only references to unlocked media will be incorporated.
  def references_to_vtt
    file = Tempfile.new(['ref-', '.vtt'], encoding: 'UTF-8')
    file.write vtt_start
    referrals_by_time.select { |r| r.item_published? && !r.item_locked? }
                     .each do |r|
      file.write r.vtt_time_span
      file.write JSON.pretty_generate(r.vtt_properties) + "\n\n"
    end
    file
  end

  def create_vtt_container!
    VttContainer.create(table_of_contents: toc_to_vtt,
                        references: references_to_vtt)
  end

  # some plain methods for items and referrals

  def proper_items
    items.where.not(sort: ['self', 'pdf_destination'])
         .where.not(start_time: nil)
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

  def screenshot_url_with_host
    return screenshot_url(host: host) unless screenshot(:normalized)
    return screenshot_url(:normalized, host: host)
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

  def geogebra_filename
    return unless geogebra.present?
    geogebra.metadata['filename']
  end

  def geogebra_size
    return unless geogebra.present?
    geogebra.metadata['size']
  end

  def geogebra_url_with_host
    geogebra_url(host: host)
  end

  def geogebra_download_url
    geogebra_url(host: download_host)
  end

  def geogebra_screenshot_url
    return '' unless geogebra.present?
    geogebra_url(:screenshot, host: host)
  end

  def manuscript_url_with_host
    manuscript_url(host: host)
  end

  def manuscript_download_url
    manuscript_url(host: download_host)
  end

  def manuscript_filename
    return unless manuscript.present?
    return manuscript.metadata['filename']
  end

  def manuscript_size
    return unless manuscript.present?
    return manuscript.metadata['size']
  end

  def manuscript_pages
    return unless manuscript.present?
    return manuscript.metadata['pages']
  end


  def manuscript_screenshot_url
    return '' unless manuscript.present?
    manuscript_url(:screenshot, host: host)
  end

  def manuscript_destinations
    return [] unless manuscript.present? && sort == 'Script'
    manuscript.metadata['destinations'] || []
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

  # methods that create card header and subheader for a medium card

  def card_header
    teachable.card_header
  end

  def card_header_teachable_path(user)
    teachable.card_header_path(user)
  end

  def card_subheader
    Medium.sort_localized_short[sort]
  end

  def sort_localized
    Medium.sort_localized[sort]
  end

  def cache_key
    super + '-' + I18n.locale.to_s
  end

  def published?
    !released.nil?
  end

  def locked?
    released == 'locked'
  end

  def restricted?
    released == 'subscribers'
  end

  def free?
    released == 'all'
  end

  def for_users?
    released == 'users'
  end

  def visible?
    released.in?(['all', 'users', 'subscribers'])
  end

  def visible_for_user?(user)
    return true if user.admin
    return true if edited_with_inheritance_by?(user)
    return false unless published?
    return false if locked?
    if teachable_type == 'Course'
      return false if restricted? && !teachable.in?(user.courses)
    end
    if teachable_type.in?(['Lecture', 'Lesson'])
      return false if restricted? && !teachable.lecture.in?(user.lectures)
    end
    true
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

  # only irrelevant media can be deleted
  def irrelevant?
    video.nil? && manuscript.nil? && external_reference_link.blank?
  end

  def teachable_select
    return nil unless teachable.present?
    teachable_type + '-' + teachable_id.to_s
  end

  # media associated to the same teachable and of the same sort
  def siblings
    teachable.media.where(sort: sort)
  end

  # the next methods all provide information about the medium, with more or
  # less details

  def compact_info_uncached
    return "#{sort_localized}.#{teachable.compact_title}" unless quizzy?
    "#{sort_localized}.#{teachable.compact_title}.\##{id}"
  end

  def compact_info
    Rails.cache.fetch("#{cache_key_with_version}/compact_info") do
      compact_info_uncached
    end
  end

  # returns description unless medium is Kaviar associated to a lesson or a
  # question, in which case details about the lesson/the question are
  # returned, or a Script

  def local_info_uncached
    return description if description.present?
    return I18n.t('admin.medium.local_info.no_title') unless undescribable?
    if sort == 'Kaviar' &&  teachable_type == 'Lesson'
        return I18n.t('admin.medium.local_info.to_session',
                      number: teachable.number,
                      date: teachable.date_localized)

    elsif sort == 'Script'
      return I18n.t('categories.script.singular')
    end
    "#{sort_localized} \##{id}"
  end

  def local_info
    Rails.cache.fetch("#{cache_key_with_version}/local_info") do
      local_info_uncached
    end
  end

  def local_info_for_admins_uncached
    return local_info unless quizzy?
    "\##{id}.#{local_info}"
  end

  def local_info_for_admins
    Rails.cache.fetch("#{cache_key_with_version}/local_info_for_admins") do
      local_info_for_admins_uncached
    end
  end

  # returns description if present, otherwise ''

  def details_uncached
    return description unless description.blank?
    unless undescribable?
      return "#{I18n.t('admin.medium.local_info.no_title')}.ID#{id}"
    end
    ''
  end

  def details
    Rails.cache.fetch("#{cache_key_with_version}/details") do
      details_uncached
    end
  end

  def title_uncached
    return compact_info if details.blank?
    compact_info + '.' + details
  end

  def title
    Rails.cache.fetch("#{cache_key_with_version}/title") do
      title_uncached
    end
  end

  # returns info made from sort, teachable title and description

  def title_for_viewers_uncached
    sort_localized + ', ' + teachable&.title_for_viewers.to_s +
      (description.present? ? ', ' + description : '')
  end

  def title_for_viewers
    Rails.cache.fetch("#{cache_key_with_version}/title_for_viewers") do
      title_for_viewers_uncached
    end
  end

  def scoped_teachable_title
    Rails.cache.fetch("#{cache_key_with_version}/scoped_teachable_title") do
      teachable.media_scope.title_for_viewers
    end
  end

  # returns info made from sort and description
  def local_title_for_viewers_uncached
    return"#{sort_localized}, #{description}" if description.present?
    if sort == 'Kaviar' && teachable.class.to_s == 'Lesson'
      return "#{I18n.t('categories.kaviar.singular')}, #{teachable.local_title_for_viewers}"
    end
    "#{sort_localized}, #{I18n.t('admin.medium.local_info.no_title')}"
  end


  # returns info made from sort and description
  def local_title_for_viewers
    Rails.cache.fetch("#{cache_key_with_version}/local_title_for_viewers") do
      local_title_for_viewers_uncached
    end
  end

  # this is used in dropdowns for compact info
  def extended_label
    Rails.cache.fetch("#{cache_key_with_version}/extended_label") do
      "#{teachable.compact_title}.\##{id}.#{description}"
    end
  end

  # returns the (cached) array of hashes describing this mediums items
  # by id, and their title from within a given course or lecture

  def items_with_references_uncached
    items.map do |i|
      {
        id: i.id,
        title_within_course: i.title_within_course,
        title_within_lecture: i.title_within_lecture
      }
    end
  end

  def items_with_references
    Rails.cache.fetch("#{cache_key_with_version}/items_with_reference") do
      items_with_references_uncached
    end
  end

  def proper?
    return true unless sort == 'RandomQuiz'
    false
  end

  def locale_with_inheritance
    locale || teachable&.locale_with_inheritance
  end

  def sanitize_type!
    update(type: 'Quiz') if sort.in?(['Quiz', 'RandomQuiz'])
    update(type: sort) if sort.in?(['Question', 'Remark'])
    update(type: nil) if !sort.in?(['Quiz', 'Question', 'Remark', 'RandomQuiz'])
  end

  def select_sorts
    result = if new_record?
               Medium.sort_localized.except('RandomQuiz')
             elsif sort.in?(['Kaviar', 'Sesam', 'Erdbeere', 'Kiwi', 'Nuesse',
                            'Reste'])
               Medium.sort_localized.except('RandomQuiz', 'Script', 'Quiz',
                                            'Question', 'Remark')
             else
               Medium.sort_localized.slice(sort)
             end
    result.map { |k, v| [v, k] }
  end

  def extracted_linked_media
    video_links = Medium.where(id: referenced_items.where(sort: 'self')
                                                   .where.not(medium: nil)
                                                   .pluck(:medium_id))
    return video_links unless manuscript.present?

    manuscript_media_ids = manuscript.metadata['linked_media'] || []
    manuscript_links = Medium.where(id: manuscript_media_ids)
    video_links.or(manuscript_links)
  end

  def linked_media_new
    Medium.where(id: linked_media_ids_cached)
  end

  def linked_media_ids_cached
    Rails.cache.fetch("#{cache_key_with_version}/linked_media_ids_cached") do
      (linked_media.pluck(:id) + extracted_linked_media.pluck(:id)).uniq
    end
  end

  def toc_items
    return [] unless sort == 'Script'
    items.where(sort: ['chapter', 'section'])
         .natural_sort_by { |x| [x.page, x.ref_number] }
  end

  def tags_outside_lesson
    return Tag.none unless teachable_type == 'Lesson'
    tags.where.not(id: teachable.tag_ids)
  end

  def extended_content
    result = []
    if teachable_type == 'Lesson' && teachable.details.present?
      result.push I18n.t('admin.medium.lesson_details_html') + teachable.details
    end
    result.push content unless content.blank?
    result
  end

  def script_items_importable?
    return unless teachable_type == 'Lesson'
    return unless teachable.lecture.content_mode == 'manuscript'
    return unless teachable.script_items.any?
    true
  end

  def import_script_items!
    return unless teachable_type == 'Lesson'
    return unless teachable.lecture.content_mode == 'manuscript'
    items = teachable.script_items
    return unless items.any?
    items.each_with_index.each do |i, j|
      Item.create(start_time: TimeStamp.new(h: 0, m:0, s: 0, ms: j),
                  sort: i.sort, description: i.description,
                  medium: self, section: i.section,
                  ref_number: i.ref_number,
                  related_items: [i])
    end
  end

  def scoped_teachable
    Rails.cache.fetch("#{cache_key_with_version}/scoped_teachable") do
      teachable&.media_scope
    end
  end

  private

  # media of type kaviar associated to a lesson and script do not require
  # a description
  def undescribable?
    (sort == 'Kaviar' && teachable.class.to_s == 'Lesson') ||
      sort == 'Script'
  end

  def quizzy?
    sort.in?(['Quiz', 'Question', 'Remark'])
  end

  def title_uncached
    return compact_info if details.blank?
    compact_info + '.' + details
  end

  def local_title_for_viewers_uncached
    return"#{sort_localized}, #{description}" if description.present?
    if sort == 'Kaviar' && teachable.class.to_s == 'Lesson'
      return "#{I18n.t('categories.kaviar.singular')}, #{teachable.local_title_for_viewers}"
    end
    "#{sort_localized}, #{I18n.t('admin.medium.local_info.no_title')}"
  end


  def touch_teachable
    return if teachable.nil?
    if teachable.course.present? && teachable.course.persisted?
      teachable.course.touch
    end
    optional_touches
  end

  def reset_released_status
    return if teachable.nil? || teachable.published?
    self.released = nil
  end

  def optional_touches
    if teachable.lecture.present? && teachable.lecture.persisted?
      teachable.lecture.touch
    end
    return unless teachable.lesson.present? && teachable.lesson.persisted?
    teachable.lesson.touch
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

  def create_self_item
    return if sort.in?(['Question', 'Remark', 'RandomQuiz'])
    Item.create(sort: 'self', medium: self)
  end

  def local_items
    return teachable.items - items if teachable_type == 'Course'
    teachable.lecture.items - items
  end

  def at_most_one_manuscript
    return true unless teachable_type == 'Lecture'
    return true unless sort == 'Script'
    if (Medium.where(sort: 'Script',
                     teachable: teachable).to_a - [self]).size.positive?
      errors.add(:sort, :lecture_manuscript_exists)
      return false
    end
    true
  end

  def script_only_for_lectures
    return true if teachable_type == 'Lecture'
    return true unless sort == 'Script'
    errors.add(:sort, :lecture_only)
    false
  end

  def no_video_for_script
    return true unless sort == 'Script'
    return true unless video.present?
    errors.add(:sort, :no_video)
    false
  end

  def no_changing_sort_to_or_from_script
    if sort_was == 'Script' && sort != 'Script'
      errors.add(:sort, :no_conversion_from_script)
      return false
    end
    if persisted? && sort_was != 'Script' && sort == 'Script'
      errors.add(:sort, :no_conversion_to_script)
      return false
    end
    true
  end

  def no_tags_for_scripts
    return true unless sort == 'Script' && tags.any?
    errors.add(:tags, :no_tags_allowed)
    false
  end

  def delete_vertices
    return unless type.in?(['Question', 'Remark'])
    if type == 'Question'
      becomes(Question).delete_vertices
      return
    end
    becomes(Remark).delete_vertices
  end

  def delete_answers
    return unless type == 'Question'
    becomes(Question).answers.delete_all
  end

  def text_join
    return unless type.in?(['Question', 'Remark'])
    return text if type == 'Remark'
    "#{text} #{becomes(Question).answers&.map(&:text_join)&.join(' ')}"
  end

  def release_state
    return released unless released.nil?
    'unpublished'
  end

  def clickerizable?
    return false unless type == 'Question'
    question = becomes(Question)
    return false unless question.answers.count.in?((2..6))
    question.answers.pluck(:value).count(true) == 1
  end

  def answers_count
    return -1 unless type == 'Question'
    becomes(Question).answers.count
  end
end
