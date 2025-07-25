# Medium class
class Medium < ApplicationRecord
  include ApplicationHelper
  include ActiveModel::Dirty

  has_many :notifications, as: :notifiable, dependent: :destroy

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
                                source: :teachable, source_type: "Lecture"
  has_many :importing_courses, through: :imports,
                               source: :teachable, source_type: "Course"

  has_many :quiz_certificates, foreign_key: "quiz_id",
                               dependent: :destroy,
                               inverse_of: :quiz

  # a medium can be in watchlists of multiple users
  has_many :watchlist_entries, dependent: :destroy
  has_many :watchlist_users, through: :watchlist_entries, source: :user

  has_many :assignments

  serialize :quiz_graph, coder: QuizGraph

  serialize :solution, coder: Solution

  serialize :publisher, coder: MediumPublisher

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
  # after creation, this creates an item of type 'self' that is just a wrapper
  # around this medium, so the medium itself can be referenced from other media
  # as an item as well
  after_create :create_self_item
  # if medium is a question or remark, delete all quiz vertices that refer to it
  before_destroy :delete_vertices
  # some information about media are cached
  # to find out whether the cache is out of date, always touch'em after saving
  after_save :touch_teachable

  # keep track of copies (in particular for Questions, Remarks)
  acts_as_tree

  # media can be commented on
  acts_as_commontable dependent: :destroy

  # scope for published/locally visible media
  # locally visible media are published (without inheritance) and unlocked
  # (they may not be globally visible as their lecture may be unpublished)
  scope :published, -> { where.not(released: nil) }
  scope :locally_visible, -> { where(released: ["all", "users"]) }
  scope :potentially_visible, lambda {
                                where(released: ["all", "users", "subscribers"])
                              }
  scope :proper, -> { where.not(sort: "RandomQuiz") }
  scope :expired, lambda {
                    where(sort: "RandomQuiz").where(created_at: ...1.day.ago)
                  }

  searchable do
    text :description do
      caption
    end
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
    integer :id
    integer :teachable_id
    integer :tag_ids, multiple: true
    integer :editor_ids, multiple: true
    integer :answers_count
    integer :term_id do
      term_id || 0
    end
    integer :teacher_id do
      supervising_teacher_id
    end
    integer :subscribed_users, multiple: true
    integer :lecture do
      lecture&.id
    end
  end

  # these are all the sorts of projects we currently serve
  def self.sort_enum
    ["LessonMaterial", "WorkedExample", "Quiz", "Repetition", "Erdbeere",
     "Exercise", "Script", "Question", "Remark", "Miscellaneous", "RandomQuiz"]
  end

  # media sorts and their descriptions
  def self.sort_localized
    sort_enum.index_with do |sort|
      I18n.t("categories.#{sort.underscore}.singular")
    end
  end

  # media sorts and their short descriptions
  def self.sort_localized_short
    sort_enum.index_with do |sort|
      I18n.t("categories.#{sort.underscore}.short")
    end
  end

  def self.select_sorts
    Medium.sort_localized.except("RandomQuiz").map { |k, v| [v, k] }
  end

  def self.advanced_sorts
    ["Question", "Remark", "Erdbeere"]
  end

  def self.generic_sorts
    ["LessonMaterial", "WorkedExample", "Exercise", "Script", "Repetition", "Quiz", "Miscellaneous"]
  end

  def self.select_generic
    Medium.sort_localized.slice(*Medium.generic_sorts).map { |k, v| [v, k] }
  end

  def self.select_quizzables
    Medium.sort_localized.slice("Question", "Remark").map { |k, v| [v, k] }
  end

  def self.select_importables
    Medium.sort_localized.except("RandomQuiz", "Question", "Remark").map { |k, v| [v, k] }
  end

  # returns the array of all media subject to the conditions
  # provided by the params hash (keys: :id, :project)
  # :id represents the lecture id
  def self.search_all(params)
    lecture = Lecture.find_by(id: params[:id])
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
    return Medium.none if project.blank?

    Medium.where(sort: project.camelize)
  end

  # returns the array of all media (by title), together with their ids
  # is used in options_for_select in form helpers.
  def self.select_by_name
    Medium.where.not(sort: ["Question", "Remark", "RandomQuiz"])
          .map { |m| [m.title_for_viewers, m.id] }
  end

  # returns the array of media sorts specified by the search params
  # search_params is a hash with keys :all_types, :types
  # value for :types is an array of integers which correspond to indices
  # in the sort_enum array
  def self.search_sorts(search_params)
    return (Medium.sort_enum - ["RandomQuiz"]) unless search_params[:all_types] == "0"

    search_params[:types] || []
  end

  def self.lecture_search_option
    {
      "0" => "all",
      "1" => "subscribed",
      "2" => "custom"
    }
  end

  # returns search results for the media search with search_params provided
  # by the controller
  def self.search_by(search_params, _page)
    # If the search is initiated from the start page, you can only get
    # generic media sorts as results even if the 'all' radio button
    # is seleted
    if search_params[:all_types] == "1"
      search_params[:types] =
        if search_params[:from] == "start"
          Medium.generic_sorts
        else
          []
        end
    end
    search_params[:teachable_ids] = TeachableParser.new(search_params)
                                                   .teachables_as_strings
    if search_params[:all_editors] == "1" || search_params[:all_editors].nil?
      search_params[:editor_ids] =
        []
    end
    # add media without term to current term

    search_params[:all_terms] = "1" if search_params[:all_terms].blank?
    search_params[:all_teachers] = "1" if search_params[:all_teachers].blank?
    search_params[:term_ids].push("0") if search_params[:term_ids].present?
    user = User.find_by(id: search_params[:user_id])
    search = Sunspot.new_search(Medium)
    search.build do
      with(:sort, search_params[:types])
      without(:sort, "RandomQuiz")
      without(:sort, Medium.advanced_sorts) unless user&.admin_or_editor?
      with(:editor_ids, search_params[:editor_ids])
      with(:teachable_compact, search_params[:teachable_ids])
      unless search_params[:all_terms] == "1"
        with(:term_id,
             search_params[:term_ids])
      end
      unless search_params[:all_teachers] == "1"
        with(:teacher_id,
             search_params[:teacher_ids])
      end
    end
    unless search_params[:answers_count] == "irrelevant"
      search.build do
        with(:answers_count, [-1, search_params[:answers_count].to_i])
      end
    end
    unless search_params[:access] == "irrelevant"
      search.build do
        with(:release_state, search_params[:access])
      end
    end
    if search_params[:all_tags] == "0" && search_params[:tag_ids].any?
      search.build do
        if search_params[:tag_operator] == "and"
          with(:tag_ids).all_of(search_params[:tag_ids])
        else
          with(:tag_ids).any_of(search_params[:tag_ids])
        end
      end
    end
    if search_params[:fulltext].present?
      search.build do
        fulltext(search_params[:fulltext]) do
          boost_fields(description: 2.0)
        end
      end
    end
    if search_params[:lecture_option].present?
      case Medium.lecture_search_option[search_params[:lecture_option]]
      when "subscribed"
        search.build do
          with(:subscribed_users, search_params[:user_id])
        end
      when "custom"
        search.build do
          with(:lecture, search_params[:media_lectures])
        end
      end
    end
    # this is needed for kaminari to function correctly
    search.build do
      paginate(page: 1, per_page: Medium.count)
    end
    search
  end

  def self.search_questions_by_tags(search_params)
    search = Sunspot.new_search(Medium)
    search.build do
      with(:sort, "Question")
      with(:teachable_compact, search_params[:teachable_ids])
      with(:tag_ids).all_of(search_params[:tag_ids])
      paginate(per_page: Question.count)
    end
    search
  end

  def self.similar_courses(search_string)
    jarowinkler = FuzzyStringMatch::JaroWinkler.create(:pure)
    titles = Medium.pluck(:description)
    titles.select do |t|
      jarowinkler.getDistance(t.downcase, search_string.downcase) > 0.8
    end
  end

  # protected items are items of type 'pdf_destination' inside associated to
  # this medium that are referred to from other media or from an entry
  # within the table of contents of the video associated to this medium.
  # they will not get auto-deleted when an attached pdf is removed, only if
  # the user insists (this way they are protected for example in the situation
  # where the user temporarily commented out some part of the manuscript)
  def protected_items
    return [] unless sort == "Script"

    pdf_items = Item.where(medium: self).where.not(pdf_destination: nil)
    Referral.where(item: pdf_items).map(&:item).uniq
  end

  def vanished_items
    return [] unless sort == "Script"

    Item.where(medium: self)
        .where.not(sort: "self")
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
    return unless sort == "Script"

    irrelevant_items.delete_all
    result = missing_items_outside_quarantine.pluck(:pdf_destination)
    missing_items_outside_quarantine.update(quarantine: true)
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
    return true if teachable.is_a?(Talk) && user.in?(teachable.speakers)

    false
  end

  def editors_with_inheritance
    return [] if sort == "RandomQuiz"

    result = (editors&.to_a&.+ teachable.lecture&.editors.to_a +
      [teachable.lecture&.teacher] + teachable.course.editors.to_a).uniq.compact
    return result unless teachable.is_a?(Talk)

    (result + teachable.speakers).uniq
  end

  # returns the array of users that are eligible to obtain editing rights
  # for the given medium from the given user
  def eligible_editors(user)
    result = editors_with_inheritance

    result.concat(lecture.speakers) if teachable.is_a?(Talk) && user.can_edit?(lecture)

    result << user if user.admin?
    result.uniq
  end

  # creates a .vtt tmp file (and returns it), which contains
  # all data needed by the thyme player to realize the toc
  def toc_to_vtt
    file = Tempfile.new(["toc-", ".vtt"], encoding: "UTF-8")
    file.write(vtt_start)
    proper_items_by_time.reject(&:hidden).each do |i|
      file.write(i.vtt_time_span)
      file.write(i.vtt_reference)
    end
    file
  end

  # creates a .vtt file (and returns it), which contains
  # all data needed by the thyme player to realize references
  # Note: Only references to unlocked media will be incorporated.
  def references_to_vtt
    file = Tempfile.new(["ref-", ".vtt"], encoding: "UTF-8")
    file.write(vtt_start)
    referrals_by_time.select { |r| r.item_published? && !r.item_locked? }
                     .each do |r|
      file.write(r.vtt_time_span)
      file.write("#{JSON.pretty_generate(r.vtt_properties)}\n\n")
    end
    file
  end

  def create_vtt_container!
    VttContainer.create(table_of_contents: toc_to_vtt,
                        references: references_to_vtt)
  end

  # some plain methods for items and referrals

  def proper_items
    items.where.not(sort: ["self", "pdf_destination"])
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

    screenshot_url(:normalized, host: host)
  end

  def video_url
    return if video.blank?

    video.url(host: host)
  end

  def video_download_url
    video.url(host: download_host)
  end

  def video_filename
    return if video.blank?

    video.metadata["filename"]
  end

  def video_size
    return if video.blank?

    video.metadata["size"]
  end

  def video_resolution
    return if video.blank?

    video.metadata["resolution"]
  end

  def video_duration
    return if video.blank?

    video.metadata["duration"]
  end

  def video_duration_hms_string
    return if video.blank?

    TimeStamp.new(total_seconds: video_duration).hms_string
  end

  def geogebra_filename
    return if geogebra.blank?

    geogebra.metadata["filename"]
  end

  def geogebra_size
    return if geogebra.blank?

    geogebra.metadata["size"]
  end

  def geogebra_url_with_host
    geogebra_url(host: host)
  end

  def geogebra_download_url
    geogebra_url(host: download_host)
  end

  def geogebra_screenshot_url
    return "" if geogebra.blank?

    geogebra_url(:screenshot, host: host)
  end

  def manuscript_url_with_host
    return "#{manuscript_url(host: host)}/#{manuscript_filename}" if ENV["REWRITE_ENABLED"] == "1"

    manuscript_url(host: host)
  end

  def manuscript_download_url
    manuscript_url(host: download_host)
  end

  def manuscript_filename
    return if manuscript.blank?

    manuscript.metadata["filename"]
  end

  def manuscript_size
    return if manuscript.blank?

    manuscript.metadata["size"]
  end

  def manuscript_pages
    return if manuscript.blank?

    manuscript.metadata["pages"]
  end

  def manuscript_screenshot_url
    return "" if manuscript.blank?

    manuscript_url(:screenshot, host: host)
  end

  def manuscript_destinations
    return [] unless manuscript.present? && sort == "Script"

    manuscript.metadata["destinations"] || []
  end

  def video_width
    return if video.blank?

    video_resolution.split("x")[0].to_i
  end

  def video_height
    return if video.blank?

    video_resolution.split("x")[1].to_i
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
    return "" unless sort == "LessonMaterial" && teachable_type == "Lesson"

    teachable.section_titles || ""
  end

  # methods that create card header and subheader for a medium card

  delegate :card_header, to: :teachable

  def card_header_teachable_path(user)
    teachable.card_header_path(user)
  end

  def card_subheader
    Medium.sort_localized_short[sort]
  end

  def card_tooltip
    return Medium.sort_localized[sort] unless sort == "Exercise" && file_last_edited

    I18n.t("categories.exercise.singular_updated")
  end

  def sort_localized
    Medium.sort_localized[sort]
  end

  def subheader_style
    return "badge bg-secondary" unless sort == "Exercise" && file_last_edited

    "badge bg-danger"
  end

  def cache_key
    "#{super}-#{I18n.locale}"
  end

  def published?
    !released.nil?
  end

  def locked?
    released == "locked"
  end

  def restricted?
    released == "subscribers"
  end

  def free?
    released == "all"
  end

  def for_users?
    released == "users"
  end

  def visible?
    released.in?(["all", "users", "subscribers"])
  end

  def visible_for_user?(user)
    return true if user.admin
    return true if edited_with_inheritance_by?(user)
    return false unless published?
    return false if locked?

    return false if teachable_type == "Course" && restricted? && !teachable.in?(user.courses)
    if teachable_type.in?(["Lecture", "Lesson",
                           "Talk"]) && restricted? && !teachable.lecture.in?(user.lectures)
      return false
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
    return nil if teachable.blank?

    "#{teachable_type}-#{teachable_id}"
  end

  # media associated to the same teachable and of the same sort
  def siblings
    teachable.media.where(sort: sort)
  end

  # the next methods all provide information about the medium, with more or
  # less details

  def compact_info_uncached
    return "#{sort_localized}.#{teachable.compact_title}" unless quizzy?

    "#{sort_localized}.#{teachable.compact_title}.##{id}"
  end

  def compact_info
    Rails.cache.fetch("#{cache_key_with_version}/compact_info") do
      compact_info_uncached
    end
  end

  # returns description unless medium is LessonMaterial associated to a lesson or a
  # question, in which case details about the lesson/the question are
  # returned, or a Script

  def local_info_uncached
    return description if description.present?
    return I18n.t("admin.medium.local_info.no_title") unless undescribable?

    if sort == "LessonMaterial" && teachable_type == "Lesson"
      return I18n.t("admin.medium.local_info.to_session",
                    number: teachable.number,
                    date: teachable.date_localized)

    elsif sort == "Script"
      return I18n.t("categories.script.singular")
    end
    "#{sort_localized} ##{id}"
  end

  def local_info
    Rails.cache.fetch("#{cache_key_with_version}/local_info") do
      local_info_uncached
    end
  end

  def local_info_for_admins_uncached
    return local_info unless quizzy?

    "##{id}.#{local_info}"
  end

  def local_info_for_admins
    Rails.cache.fetch("#{cache_key_with_version}/local_info_for_admins") do
      local_info_for_admins_uncached
    end
  end

  # returns description if present, otherwise ''

  def details_uncached
    return description if description.present?
    return "#{I18n.t("admin.medium.local_info.no_title")}.ID#{id}" unless undescribable?

    ""
  end

  def details
    Rails.cache.fetch("#{cache_key_with_version}/details") do
      details_uncached
    end
  end

  def title
    Rails.cache.fetch("#{cache_key_with_version}/title") do
      title_uncached
    end
  end

  # returns info made from sort, teachable title and description

  def title_for_viewers_uncached
    description_str = description.present? ? ", #{description}" : ""
    "#{sort_localized}, #{teachable&.title_for_viewers}#{description_str}"
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
  def local_title_for_viewers
    Rails.cache.fetch("#{cache_key_with_version}/local_title_for_viewers") do
      local_title_for_viewers_uncached
    end
  end

  # this is used in dropdowns for compact info
  def extended_label
    Rails.cache.fetch("#{cache_key_with_version}/extended_label") do
      "#{teachable.compact_title}.##{id}.#{description}"
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
    return true unless sort == "RandomQuiz"

    false
  end

  def locale_with_inheritance
    locale || teachable&.locale_with_inheritance
  end

  def sanitize_type!
    update(type: "Quiz") if sort.in?(["Quiz", "RandomQuiz"])
    update(type: sort) if sort.in?(["Question", "Remark"])
    update(type: nil) unless sort.in?(["Quiz", "Question", "Remark", "RandomQuiz"])
  end

  def select_sorts
    result = if new_record?
      Medium.sort_localized.except("RandomQuiz")
    elsif sort.in?(["LessonMaterial", "WorkedExample", "Erdbeere", "Repetition", "Exercise",
                    "Miscellaneous"])
      Medium.sort_localized.except("RandomQuiz", "Script", "Quiz",
                                   "Question", "Remark")
    else
      Medium.sort_localized.slice(sort)
    end
    if teachable_type == "Talk"
      result.except!("RandomQuiz", "Question", "Remark", "Erdbeere", "Script")
    end
    result.map { |k, v| [v, k] }
  end

  def select_sorts_with_self
    (select_sorts + [[Medium.sort_localized[sort], sort]]).uniq
  end

  def extracted_linked_media
    video_links = Medium.where(id: referenced_items.where(sort: "self")
                                                   .where.not(medium: nil)
                                                   .pluck(:medium_id))
    return video_links if manuscript.blank?

    manuscript_media_ids = manuscript.metadata["linked_media"] || []
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
    return [] unless sort == "Script"

    items.where(sort: ["chapter", "section"])
         .natural_sort_by { |x| [x.page, x.ref_number] }
  end

  def tags_outside_lesson
    return Tag.none unless teachable_type == "Lesson"

    tags.where.not(id: teachable.tag_ids)
  end

  def extended_content
    result = []
    if teachable_type == "Lesson" && teachable.details.present?
      result.push(I18n.t("admin.medium.lesson_details_html") + teachable.details)
    end
    result.push(content) if content.present?
    result
  end

  def script_items_importable?
    return false unless teachable_type == "Lesson"
    return false unless teachable.lecture.content_mode == "manuscript"
    return false unless teachable.script_items.any?

    true
  end

  def import_script_items!
    return unless teachable_type == "Lesson"
    return unless teachable.lecture.content_mode == "manuscript"

    items = teachable.script_items
    return unless items.any?

    items.each_with_index.each do |i, j|
      Item.create(start_time: TimeStamp.new(h: 0, m: 0, s: 0, ms: j),
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

  def publish!
    return if published?
    return unless publisher

    success = publisher.publish!
    update(publisher: nil) if success
  end

  def release_date_set?
    return false unless publisher
    return false unless publisher.release_date

    true
  end

  def planned_release_date
    return unless publisher

    publisher.release_date
  end

  def planned_comment_lock?
    return publisher.lock_comments if publisher

    !!teachable.media_scope.try(:comments_disabled)
  end

  def becomes_quizzable
    return unless type.in?(["Question", "Remark"])
    return becomes(Question) if type == "Question"

    becomes(Remark)
  end

  def containing_watchlists(user)
    Watchlist.where(id: WatchlistEntry.where(medium: self).select(:watchlist_id),
                    user: user)
  end

  def containing_watchlists_names(user)
    watchlists = containing_watchlists(user)
    if watchlists.empty?
      ""
    else
      watchlists.pluck(:name)
    end
  end

  def collects_statistics
    video.present? || manuscript.present? || sort == "Quiz"
  end

  def term_id
    teachable.term_id if teachable.instance_of?(::Lecture)
    return unless teachable.instance_of?(::Lesson)

    Lecture.find_by(id: teachable.lecture_id).term_id
  end

  def supervising_teacher_id
    return teachable.teacher_id if teachable.instance_of?(::Lecture)
    return unless teachable.instance_of?(::Lesson)

    Lecture.find_by(id: teachable.lecture_id).teacher_id
  end

  def subscribed_users
    return teachable.user_ids if ["Lecture",
                                  "Course"].include?(teachable.class.to_s)
    return unless teachable.instance_of?(::Lesson)

    Lecture.find_by(id: teachable.lecture_id).user_ids
  end

  # Returns either the annotations status (1 = activated, 0 = deactivated)
  # of this medium or the annotations status of the associated lecture
  # if "inherit from lecture" was selected (i.e. if the annotations status of
  # this medium is -1).
  def get_annotations_status # rubocop:todo Naming/AccessorMethodName
    return lecture.annotations_status if annotations_status == -1 && lecture.present?

    annotations_status
  end

  def annotations_visible?(user)
    is_teacher = edited_with_inheritance_by?(user)
    is_activated = (get_annotations_status == 1)
    is_teacher && is_activated
  end

  def valid_annotations_status?
    [-1, 0, 1].include?(annotations_status)
  end

  private

    # media of type LessonMaterial associated to a lesson and script do not require
    # a description
    def undescribable?
      (sort == "LessonMaterial" && teachable.instance_of?(::Lesson)) ||
        sort == "Script"
    end

    def quizzy?
      sort.in?(["Quiz", "Question", "Remark"])
    end

    def title_uncached
      return compact_info if details.blank?

      "#{compact_info}.#{details}"
    end

    # returns info made from sort and description
    def local_title_for_viewers_uncached
      return "#{sort_localized}, #{description}" if description.present?

      if sort == "LessonMaterial" && teachable.instance_of?(::Lesson)
        return "#{I18n.t("categories.lesson_material.singular")}, " \
               "#{teachable.local_title_for_viewers}"
      end

      "#{sort_localized}, #{I18n.t("admin.medium.local_info.no_title")}"
    end

    def touch_teachable
      return if teachable.nil?

      teachable.course.touch if teachable.course.present? && teachable.course.persisted?
      optional_touches
    end

    def reset_released_status
      return if teachable.nil? || teachable.published?

      self.released = nil
    end

    def optional_touches
      teachable.lecture.touch if teachable.lecture.present? && teachable.lecture.persisted?
      teachable.lesson.touch if teachable.lesson.present? && teachable.lesson.persisted?
      return unless teachable.talk.present? && teachable.talk.persisted?

      teachable.talk.touch
    end

    def vtt_start
      "WEBVTT\n\n"
    end

    def belongs_to_course?(lecture)
      teachable_type == "Course" && teachable == lecture.course
    end

    def belongs_to_lecture?(lecture)
      teachable_type == "Lecture" && teachable == lecture
    end

    def belongs_to_lesson?(lecture)
      teachable_type == "Lesson" && teachable.lecture == lecture
    end

    def create_self_item
      return if sort.in?(["Question", "Remark", "RandomQuiz"])

      Item.create(sort: "self", medium: self)
    end

    def local_items
      return teachable.items - items if teachable_type == "Course"

      teachable.lecture.items - items
    end

    def at_most_one_manuscript
      return true unless teachable_type == "Lecture"
      return true unless sort == "Script"

      if (Medium.where(sort: "Script",
                       teachable: teachable).to_a - [self]).size.positive?
        errors.add(:sort, :lecture_manuscript_exists)
        return false
      end
      true
    end

    def script_only_for_lectures
      return true if teachable_type == "Lecture"
      return true unless sort == "Script"

      errors.add(:sort, :lecture_only)
      false
    end

    def no_video_for_script
      return true unless sort == "Script"
      return true if video.blank?

      errors.add(:sort, :no_video)
      false
    end

    def no_changing_sort_to_or_from_script
      if sort_was == "Script" && sort != "Script"
        errors.add(:sort, :no_conversion_from_script)
        return false
      end
      if persisted? && sort_was != "Script" && sort == "Script"
        errors.add(:sort, :no_conversion_to_script)
        return false
      end
      true
    end

    def no_tags_for_scripts
      return true unless sort == "Script" && tags.any?

      errors.add(:tags, :no_tags_allowed)
      false
    end

    def delete_vertices
      return unless type.in?(["Question", "Remark"])

      if type == "Question"
        becomes(Question).delete_vertices
        return
      end
      becomes(Remark).delete_vertices
    end

    def text_join
      return unless type.in?(["Question", "Remark"])
      return text if type == "Remark"

      "#{text} #{becomes(Question).answers&.map(&:text_join)&.join(" ")}"
    end

    def release_state
      return released unless released.nil?

      "unpublished"
    end

    def answers_count
      return -1 unless type == "Question"

      becomes(Question).answers.count
    end
end
