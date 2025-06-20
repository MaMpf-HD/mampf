# Lecture class
class Lecture < ApplicationRecord
  include ApplicationHelper

  belongs_to :course

  has_many :notifications, as: :notifiable, dependent: :destroy

  # teacher is the user that gives the lecture
  belongs_to :teacher, class_name: "User"

  # a lecture takes place in a certain term, except those where the course
  # is marked as term_independent
  belongs_to :term, optional: true

  # a lecture has many chapters, who have positions
  has_many :chapters, -> { order(position: :asc) },
           dependent: :destroy,
           inverse_of: :lecture

  # during the term, a lot of lessons take place for this lecture
  has_many :lessons, -> { order(date: :asc, id: :asc) },
           dependent: :destroy,
           after_add: :touch_siblings,
           after_remove: :touch_siblings,
           inverse_of: :lecture

  # a lecture has many talks, which have positions
  has_many :talks, -> { order(position: :asc) },
           dependent: :destroy,
           inverse_of: :lecture

  # being a teachable (course/lecture/lesson), a lecture has associated media
  has_many :media, -> { order(position: :asc) },
           as: :teachable,
           inverse_of: :teachable

  has_many :vignettes_questionnaires, -> { order(id: :asc) },
           class_name: "Vignettes::Questionnaire",
           dependent: :destroy,
           inverse_of: :lecture

  has_many :vignettes_codenames,
           class_name: "Vignettes::Codename",
           dependent: :destroy,
           inverse_of: :lecture

  has_one :vignettes_completion_message,
          class_name: "Vignettes::CompletionMessage",
          dependent: :destroy,
          inverse_of: :lecture

  # in a lecture, you can import other media
  has_many :imports, as: :teachable, dependent: :destroy
  has_many :imported_media, through: :imports, source: :medium

  # a lecture has many users who have subscribed it in their profile
  has_many :lecture_user_joins, dependent: :destroy
  has_many :users, -> { distinct }, through: :lecture_user_joins

  # a lecture has many users who have starred it (fans)
  has_many :user_favorite_lecture_joins, dependent: :destroy
  has_many :fans, -> { distinct }, through: :user_favorite_lecture_joins,
                                   source: :user

  # a lecture has many editors
  # these are users different from the teacher who have the right to
  # modify lecture contents
  has_many :editable_user_joins, as: :editable, dependent: :destroy
  has_many :editors, through: :editable_user_joins, as: :editable,
                     source: :user

  # a lecture has many announcements
  has_many :announcements, dependent: :destroy

  # a lecture has many tutorials
  has_many :tutorials, -> { order(:title) },
           inverse_of: :lecture

  # a lecture has many assignments (e.g. exercises with deadlines)
  has_many :assignments

  # a lecture has many vouchers that can be redeemed to promote
  # users to tutors, editors or teachers
  has_many :vouchers, dependent: :destroy

  # a lecture has many structure_ids, referring to the ids of structures
  # in the erdbeere database
  serialize :structure_ids, type: Array, coder: YAML

  # we do not allow that a teacher gives a certain lecture in a given term
  # of the same sort twice
  validates :course, uniqueness: { scope: [:teacher_id, :term_id, :sort] }

  validates :content_mode, inclusion: { in: ["video", "manuscript"] }

  validates :sort, inclusion: { in: ["lecture", "seminar", "oberseminar",
                                     "proseminar", "special", "vignettes"] }

  validates :term, presence: { unless: :term_independent? }

  validate :absence_of_term, if: :term_independent?

  validate :only_one_lecture, if: :term_independent?, on: :create

  validates :submission_max_team_size,
            numericality: { only_integer: true,
                            greater_than: 0 },
            allow_nil: true

  validates :submission_grace_period,
            numericality: { only_integer: true,
                            greater_than: -1 },
            allow_nil: true

  # if the lecture is destroyed, its forum (if existent) should be destroyed
  # as well
  before_destroy :destroy_forum
  # as a teacher has editing rights by definition, we do not need him in the
  # list of editors
  after_save :remove_teacher_as_editor

  # some information about media and lessons are cached
  # to find out whether the cache is out of date, always touch'em after saving
  after_save :touch_media
  after_save :touch_lessons
  after_save :touch_chapters
  after_save :touch_sections

  # scopes
  scope :published, -> { where.not(released: nil) }

  scope :no_term, -> { where(term: nil) }

  scope :restricted, -> { where.not(passphrase: ["", nil]) }

  scope :seminar, -> { where(sort: ["seminar", "oberseminar", "proseminar"]) }

  searchable do
    integer :term_id do
      term_id || 0
    end
    integer :teacher_id
    string :sort
    text :text do
      "#{course.title} #{course.short_title}"
    end
    integer :program_ids, multiple: true do
      course.divisions.pluck(:program_id).uniq
    end
    integer :editor_ids, multiple: true
    boolean :is_published do
      published?
    end
    # these two are for ordering
    time :sort_date do
      begin_date
    end
    string :sort_title do
      ActiveSupport::Inflector.transliterate(course.title).downcase
    end
  end

  def self.select
    Lecture.all.map { |l| [l.title, l.id] }
  end

  # The next methods coexist for lectures and lessons as well.
  # Therefore, they can be called on any *teachable*

  def lecture
    self
  end

  def lesson
  end

  def talk
  end

  def media_scope
    self
  end

  def selector_value
    "Lecture-#{id}"
  end

  def title
    return course.title unless term

    "(#{sort_localized_short}) #{course.title}, #{term.to_label}"
  end

  def title_no_term
    return course.title unless term

    "(#{sort_localized_short}) #{course.title}"
  end

  def title_term_short
    "(#{sort_localized_short}) #{term_to_label_short}"
  end

  def to_label
    title
  end

  def compact_title
    return course.compact_title unless term

    "#{sort_localized_short}.#{course.compact_title}.#{term.compact_title}"
  end

  def title_for_viewers
    Rails.cache.fetch("#{cache_key_with_version}/title_for_viewers") do
      short_title
    end
  end

  def locale_with_inheritance
    locale || course.locale
  end

  def long_title
    title
  end

  def card_header
    title
  end

  def card_header_path(user)
    return unless user.lectures.include?(self)

    lecture_path
  end

  def cache_key
    "#{super}-#{I18n.locale}"
  end

  def restricted?
    passphrase.present?
  end

  def visible_for_user?(user)
    return true if user.admin
    return true if edited_by?(user)
    return false unless published?
    return false if restricted? && !in?(user.lectures)

    true
  end

  # the next methods deal with the lecture's tags
  # tags are associated to courses, sections, media and lessons
  # in this context, tags associated to courses and to sections are relevant
  # the first ones refer to a kind of top-down-tagging, the second ones
  # refer to a bottom-up-tagging

  # lecture tags are all tags that are associated to sections within chapters
  # associated to the lecture
  def tags
    Rails.cache.fetch("#{cache_key_with_version}/tags") do
      chapters.includes(sections: [tags: [:notions]]).map(&:sections).flatten.collect(&:tags)
              .flatten.uniq
    end
  end

  # course tags are all tags that are lecture tags as well as tags that are
  # associated to the lecture's course
  def course_tags(lecture_tags: tags)
    lecture_tags & course.tags
  end

  # extra tags are tags that are lecture tags but not course tags
  def extra_tags(lecture_tags: tags)
    lecture_tags - course.tags
  end

  # deferred tags are tags that are course tags but not lecture tags
  def deferred_tags(lecture_tags: tags)
    course.tags.includes(:notions) - lecture_tags
  end

  def tags_including_media_tags
    (tags +
       lessons.includes(media: :tags)
              .map(&:media).flatten.uniq
              .select { |m| m.released.in?(["all", "users", "subscribers"]) }
              .map(&:tags).flatten +
       media.includes(:tags)
            .select { |m| m.released.in?(["all", "users", "subscribers"]) }
            .map(&:tags).flatten).uniq
  end

  # lecture items are all items associated to sections within chapters
  # associated to the lecture
  def items
    chapters.collect { |c| c.sections.includes(:items) }
            .flatten.collect(&:items).flatten
  end

  # returns content items as provided by Script
  # (relevant if content mode is set to manuscript):
  # - disregards equations, exercises and labels without description
  #   and items in quarantine
  def script_items_by_position
    return [] unless manuscript

    hidden_chapters = Chapter.where(hidden: true)
    hidden_sections = Section.where(hidden: true)
                             .or(Section.where(chapter: hidden_chapters))
    Item.where(medium: lecture.manuscript)
        .where.not(sort: "self")
        .content
        .unquarantined
        .unhidden
        .where.not(section: hidden_sections)
        .order(:position)
  end

  def manuscript
    Medium.where(sort: "Script", teachable: lecture)&.first
  end

  # returns the ARel of all media whose teachable's lecture is the given lecture

  def media_with_inheritance_uncached
    Medium.proper.where(teachable: self)
          .or(Medium.proper.where(teachable: lessons))
          .or(Medium.proper.where(teachable: talks))
  end

  def media_with_inheritance_uncached_eagerload_stuff
    Medium.includes(:tags, teachable: [lecture: [:lessons, :talks]])
          .proper.where(teachable: self)
          .or(Medium.includes(:tags, teachable: [lecture: [:lessons, :talks]])
                    .proper.where(teachable: lessons + talks))
  end

  def media_with_inheritance
    Rails.cache.fetch("#{cache_key_with_version}/media_with_inheritance") do
      media_with_inheritance_uncached
    end
  end

  # returns the array of all items (described by their title and id) which
  # are associated to media associated (with inheritance) to the lecture
  def media_items_with_inheritance
    media_with_inheritance.collect do |m|
      m.items_with_references.collect { |i| [i[:title_within_lecture], i[:id]] }
    end
                          .reduce(:concat)
  end

  def published?
    !released.nil?
  end

  # The next methods return if there are any media in the LessonMaterial, WorkedExample etc.
  # projects that are associated to this lecture *with inheritance*
  # These methods make use of caching.

  def lesson_material?(user)
    project?("lesson_material", user) || imported_any?("lesson_material")
  end

  def worked_example?(user)
    project?("worked_example", user) || imported_any?("worked_example")
  end

  def quiz?(user)
    project?("quiz", user) || imported_any?("quiz")
  end

  def erdbeere?(user)
    project?("erdbeere", user) || imported_any?("erdbeere")
  end

  def repetition?(user)
    project?("repetition", user) || imported_any?("repetition")
  end

  def exercise?(user)
    project?("exercise", user) || imported_any?("exercise")
  end

  def script?(user)
    project?("script", user) || imported_any?("exercise")
  end

  def miscellaneous?(user)
    project?("miscellaneous", user) || imported_any?("miscellaneous")
  end

  def questionnaire?
    Rails.cache.fetch("#{cache_key_with_version}/has_questionnaire") do
      Vignettes::Questionnaire.exists?(lecture_id: id)
    end
  end

  # the next methods put together some information on the lecture (teacher,
  # term, title) in various combinations

  def short_title
    return course.short_title unless term

    "(#{sort_localized_short}) #{course.short_title} #{term.to_label_short}"
  end

  def short_title_release
    return short_title if published?

    "#{short_title} (#{I18n.t("access.unpublished")})"
  end

  def short_title_brackets
    return course.short_title unless term

    "(#{sort_localized_short}) #{course.short_title} (#{term.to_label_short})"
  end

  def title_with_teacher
    return title unless teacher.present? && teacher.name.present?

    "#{title} (#{teacher.name})"
  end

  def title_with_teacher_no_type
    return "#{course.title}, (#{teacher.name})" unless term

    "#{course.title}, #{term.to_label} (#{teacher.name})"
  end

  def term_teacher_info
    return term_to_label if teacher.blank?
    return term_to_label if teacher.name.blank?
    return "#{course.title}, #{teacher.name}" unless term

    "(#{sort_localized_short}) #{term_to_label}, #{teacher.name}"
  end

  def term_teacher_published_info
    return term_teacher_info if published?

    "#{term_teacher_info} (#{I18n.t("access.unpublished")})"
  end

  def title_term_info
    "(#{sort_localized_short}) #{course.title}, #{term_to_label}"
  end

  def title_term_info_no_type
    return course.title unless term

    "#{course.title}, #{term_to_label}"
  end

  def title_teacher_info
    return course.title unless teacher.present? && teacher.name.present?

    "(#{sort_localized_short}) #{course.title} (#{teacher.name})"
  end

  def sort_localized
    I18n.t("admin.lecture.#{sort}")
  end

  def sort_localized_short
    I18n.t("admin.lecture.#{sort}_short")
  end

  # returns whether the lecture is newest among all lectures associated to its
  # course
  def newest?
    self == course.lectures_by_date.first
  end

  def latest?
    course.lectures_by_date.first == self
  end

  # lecture sections are all sections within chapters associated to the lecture
  def sections
    Section.where(chapter: chapters)
  end

  def sections_cached
    Rails.cache.fetch("#{cache_key_with_version}/sections") do
      sections.to_a
    end
  end

  # Returns the list of sections of this lecture (by label), together with
  # their ids.
  # Is used in options_for_select in form helpers.
  def section_selection
    Rails.cache.fetch("#{cache_key_with_version}/section_selection") do
      sections.natural_sort_by(&:calculated_number)
              .map { |s| [s.to_label, s.id] }
    end
  end

  # Returns a hash of sections and associated tags (by label and id)
  def section_tag_selection
    sections.map do |s|
      { section: s.id, tags: s.tags.map { |t| [t.id, t.title] } }
    end
  end

  # Returns the list of chapters of this lecture (by label), together with
  # their ids.
  # Is used in options_for_select in form helpers.
  def select_chapters
    chapters.order(:position).reverse.map { |c| [c.to_label, c.position] }
  end

  # Returns the list of editors of this lecture (by info), together with
  # their ids.
  # Is used in options_for_select in form helpers
  def select_editors
    editors.map { |e| [e.info, e.id] }
  end

  # returns the array of lectures that can be edited by the given user,
  # together with a string made up of 'Lecture-' and their id
  # Is used in options_for_select in form helpers.
  def self.editable_selection(user)
    if user.admin?
      return Lecture.sort_by_date(Lecture.includes(:term).all)
                    .map { |l| [l.title_for_viewers, "Lecture-#{l.id}"] }
    end
    Lecture.sort_by_date(Lecture.includes(:course, :editors).all)
           .select { |l| l.edited_by?(user) }
           .map { |l| [l.title_for_viewers, "Lecture-#{l.id}"] }
  end

  # the next methods provide infos on editors and teacher

  def editors_with_inheritance
    ([teacher] + editors.to_a + course.editors).to_a
  end

  # the next methods provide user related information about the lecture

  def edited_by?(user)
    return true if editors_with_inheritance.include?(user)

    false
  end

  # returns path for show action of the lecture's course,
  def path(user)
    return unless user.lectures.include?(self)

    Rails.application.routes.url_helpers
         .lecture_path(self)
  end

  def last_chapter_by_position
    chapters.order(:position).last
  end

  # an orphaned lesson is a lesson in this lecture which has no sections
  # actually, the existence of something like that should be prevented
  # by the GUI
  def orphaned_lessons
    lessons.includes(:lesson_section_joins, :sections)
           .select { |l| l.sections.blank? }
  end

  # for a given list of media, sorts them as follows:
  # 1) media associated to the lecture, sorted first by boost and second
  # by creation date
  # 2) media associated to lessons of the lecture, sorted by lesson numbers
  def lecture_lesson_results(filtered_media)
    lecture_results = filtered_media.where(teachable: self)
                                    .order(boost: :desc, created_at: :desc)
    lesson_results = filtered_media.where(teachable:
                                            Lesson.where(lecture: self))
    talk_results = filtered_media.where(teachable:
                                            Talk.where(lecture: self))
    lecture_results +
      lesson_results.includes(:teachable)
                    .sort_by do |m|
                      [order_factor * m.lesson.date.jd,
                       order_factor * m.lesson.id,
                       m.position]
                    end +
      talk_results.includes(:teachable).sort_by do |m|
        m.teachable.position
      end
  end

  def order_factor
    return -1 if lecture.term.blank?
    return -1 if lecture.term.active

    1
  end

  def begin_date
    Rails.cache.fetch("#{cache_key_with_version}/begin_date") do
      term&.begin_date || Term.active.begin_date || Time.zone.today
    end
  end

  # this is depracated in favor of <=>
  # REPLACE all occurences and delete this method
  def self.sort_by_date(lectures)
    lectures.sort_by(&:begin_date).reverse
  end

  def forum_title
    "#{title} [#{teacher.name}]"
  end

  def forum?
    forum_id.present?
  end

  def forum
    Thredded::Messageboard.find_by(id: forum_id)
  end

  # extract how many posts in the lecture's forum have not been read
  # by the user
  def unread_forum_topics_count(user)
    return unless forum?

    forum_relation = Thredded::Messageboard.where(id: forum_id)
    forum_view =
      Thredded::MessageboardGroupView.grouped(forum_relation,
                                              user: user,
                                              with_unread_topics_counts: true)
    forum_view&.first&.messageboards&.first&.unread_topics_count.to_i
  end

  # as there is no show action for lessons, this is the path to the show action
  # for courses, with the lecture on top in the carousel
  def lecture_path
    Rails.application.routes.url_helpers
         .lecture_path(self)
  end

  def self.sorts
    ["lecture", "seminar", "proseminar", "oberseminar", "vignettes"]
  end

  def self.sort_localized
    Lecture.sorts.index_with { |s| I18n.t("admin.lecture.#{s}") }
  end

  def self.select_sorts
    Lecture.sort_localized.invert.to_a
  end

  def seminar?
    return true if sort.in?(["seminar", "proseminar", "oberseminar"])

    false
  end

  def chapter_name
    return "chapter" unless seminar?

    "talk"
  end

  def comments_closed?
    media_with_inheritance.map { |media| media.commontator_thread.is_closed? }.all?
  end

  def close_comments!(user)
    media_with_inheritance.each do |m|
      m.commontator_thread.close(user)
    end
  end

  def open_comments!(_user)
    media_with_inheritance.select { |m| m.commontator_thread.is_closed? }
                          .each { |m| m.commontator_thread.reopen }
  end

  def self.in_current_term
    Lecture.where(term: Term.active)
  end

  def <=>(other)
    return 0 if self == other
    return 1 if begin_date < other.begin_date
    return 1 if term == other.term &&
                ActiveSupport::Inflector.transliterate(course.title) >
                ActiveSupport::Inflector.transliterate(other.course.title)
    return 1 if term == other.term && course == other.course &&
                sort_localized < other.sort_localized

    -1
  end

  def subscribed_by?(user)
    in?(user.lectures)
  end

  def self.search_by(search_params, page)
    if search_params[:all_types] == "1" || search_params[:types].nil?
      search_params[:types] =
        []
    end
    if search_params[:all_terms] == "1" || search_params[:term_ids].nil?
      search_params[:term_ids] =
        []
    end
    if search_params[:all_teachers] == "1" || search_params[:teacher_ids].nil?
      search_params[:teacher_ids] =
        []
    end
    if search_params[:all_programs] == "1" || search_params[:program_ids].nil?
      search_params[:program_ids] =
        []
    end
    search = Sunspot.new_search(Lecture)
    # add lectures without term to current term
    if Term.active.try(:id).to_i.to_s.in?(search_params[:term_ids])
      search_params[:term_ids].push("0")
    end
    search.build do
      with(:sort, search_params[:types]) unless search_params[:types].empty?
      unless search_params[:teacher_ids].empty?
        with(:teacher_id,
             search_params[:teacher_ids])
      end
      unless search_params[:program_ids].empty?
        with(:program_ids,
             search_params[:program_ids])
      end
      unless search_params[:term_ids].empty?
        with(:term_id,
             search_params[:term_ids])
      end
    end
    admin = User.find_by(id: search_params[:user_id])&.admin
    unless admin
      search.build do
        any_of do
          with(:is_published, true)
          with(:teacher_id, search_params[:user_id])
          with(:editor_ids, search_params[:user_id])
        end
      end
    end
    if search_params[:fulltext].present?
      search.build do
        fulltext(search_params[:fulltext])
      end
    end
    search.build do
      order_by(:sort_date, :desc)
      order_by(:sort_title, :asc)
      paginate(page: page, per_page: search_params[:per])
    end
    search
  end

  def term_to_label
    return term.to_label if term

    ""
  end

  def term_to_label_short
    return term.to_label_short if term

    ""
  end

  def tutors
    User.where(id: TutorTutorialJoin.where(tutorial: tutorials)
                                    .pluck(:tutor_id).uniq)
  end

  def submission_deletion_date
    Rails.cache.fetch("#{cache_key_with_version}/submission_deletion_date") do
      (term&.end_date || Term.active&.end_date || (Time.zone.today + 180.days)) +
        15.days
    end
  end

  def assignments_by_deadline
    assignments.group_by(&:deadline).sort
  end

  def current_assignments
    assignments_by_deadline.find { |x| x.first >= Time.zone.now }&.second
                           .to_a
  end

  def previous_assignments
    assignments_by_deadline.reverse.find { |x| x.first < Time.zone.now }&.second.to_a
  end

  def scheduled_assignments?
    media.where(sort: "Exercise").where.not(publisher: nil)
         .any? { |m| m.publisher.create_assignment }
  end

  def scheduled_assignments
    media.where(sort: "Exercise").where.not(publisher: nil)
         .select { |m| m.publisher.create_assignment }
         .map { |m| m.publisher.assignment }
  end

  def assignments?
    assignments.any? || scheduled_assignments?
  end

  def select_talks
    talks.order(:position).map { |t| [t.to_label, t.position] }
  end

  def last_talk_by_position
    talks.order(:position).last
  end

  def sort_in_brackets
    "(#{sort_localized_short})"
  end

  def neighbours
    course.lectures - [self]
  end

  def importable_toc?
    chapters.none? && neighbours.any?
  end

  def import_toc!(imported_lecture, import_sections, import_tags)
    return unless imported_lecture

    imported_lecture.chapters.each do |c|
      new_chapter = c.dup
      new_chapter.lecture = self
      new_chapter.save
      next unless import_sections

      c.sections.each { |s| s.duplicate_in_chapter(new_chapter, import_tags) }
    end
  end

  def speakers
    return User.none unless seminar?

    User.where(id: SpeakerTalkJoin.where(talk: talks).select(:speaker_id))
  end

  # Determines if the lecture is stale (i.e. older than one year).
  # The age of the lecture is determined by the begin date of the term
  # in which it was given and the begin date of the current term.
  def stale?
    older_than?(1.year)
  end

  def valid_annotations_status?
    [0, 1].include?(annotations_status)
  end

  def active_voucher_of_role(role)
    vouchers.where(role: role).active&.first
  end

  def update_tutor_status!(user, selected_tutorials)
    tutorials.find_each do |t|
      t.add_tutor(user) if selected_tutorials.include?(t)
    end
    # touch to invalidate the cache
    touch
  end

  def update_editor_status!(user)
    return if editors.include?(user)

    editors << user
    # touch to invalidate the cache
    touch
  end

  def update_teacher_status!(user)
    return if teacher == user

    previous_teacher = teacher
    update(teacher: user)
    editors << previous_teacher
    # touch to invalidate the cache
    touch
  end

  def update_speaker_status!(user, selected_talks)
    talks.find_each do |t|
      t.add_speaker(user) if selected_talks.include?(t)
    end
    # touch to invalidate the cache
    touch
  end

  def eligible_as_tutors
    (tutors + Redemption.tutors_by_redemption_in(self) + editors + [teacher]).uniq
    # the first one should (in the future) actually be contained in the sum of
    # the other ones, but in the transition phase where some tutor statuses were
    # still given by the old system, this will not be true
  end

  def eligible_as_editors
    (editors + Redemption.editors_by_redemption_in(self) + course.editors - [teacher]).uniq
    # the first one should (in the future) actually be contained in the sum of
    # the other ones, but in the transition phase where some editor statuses were
    # still given by the old system, this will not be true
  end

  def eligible_as_teachers
    (User.teachers + editors + course.editors + [teacher]).uniq
  end

  def eligible_as_speakers
    (speakers + Redemption.speakers_by_redemption_in(self) + editors + [teacher]).uniq
    # the first one should (in the future) actually be contained in the sum of
    # the other ones, but in the transition phase where some editor statuses were
    # still given by the old system, this will not be true
  end

  def editors_and_teacher
    ([teacher] + editors).uniq
  end

  def tutorials_with_tutor(tutor)
    tutorials.where(id: tutorial_ids_for_tutor(tutor))
  end

  def tutorials_without_tutor(tutor)
    tutorials.where.not(id: tutorial_ids_for_tutor(tutor))
  end

  def talks_with_speaker(speaker)
    talks.where(id: talk_ids_for_speaker(speaker))
  end

  def talks_without_speaker(speaker)
    talks.where.not(id: talk_ids_for_speaker(speaker))
  end

  def vignettes?
    vignettes_questionnaires.any?
  end

  private

    # used for after save callback
    def remove_teacher_as_editor
      editors.delete(teacher)
    end

    # looks in the cache if there are any media associated *with inheritance*
    # to this lecture and a given project (lesson_material, worked_example etc.)
    def project_as_user?(project)
      Rails.cache.fetch("#{cache_key_with_version}/#{project}") do
        Medium.exists?(sort: medium_sort[project],
                       released: ["all", "users", "subscribers"],
                       teachable: self) ||
          Medium.exists?(sort: medium_sort[project],
                         released: ["all", "users", "subscribers"],
                         teachable: lessons) ||
          Medium.exists?(sort: medium_sort[project],
                         released: ["all", "users", "subscribers"],
                         teachable: talks) ||
          Medium.exists?(sort: medium_sort[project],
                         released: ["all", "users", "subscribers"],
                         teachable: course)
      end
    end

    def imported_any?(project)
      Rails.cache.fetch("#{cache_key_with_version}/imported_#{project}") do
        imported_media.exists?(sort: medium_sort[project],
                               released: ["all", "users"])
      end
    end

    def project?(project, user)
      return project_as_user?(project) unless edited_by?(user) || user.admin

      course_media = if user.in?(course.editors) || user.admin
        Medium.exists?(sort: medium_sort[project],
                       teachable: course)
      else
        Medium.exists?(sort: medium_sort[project],
                       released: ["all", "users", "subscribers"],
                       teachable: course)
      end
      lecture_media = Medium.exists?(sort: medium_sort[project],
                                     teachable: self)
      lesson_media = Medium.exists?(sort: medium_sort[project],
                                    teachable: lessons)
      talk_media = Medium.exists?(sort: medium_sort[project],
                                  teachable: talks)
      course_media || lecture_media || lesson_media || talk_media
    end

    def medium_sort
      { "lesson_material" => ["LessonMaterial"],
        "worked_example" => ["WorkedExample"],
        "repetition" => ["Repetition"],
        "quiz" => ["Quiz"],
        "exercise" => ["Exercise"],
        "erdbeere" => ["Erdbeere"],
        "script" => ["Script"],
        "miscellaneous" => ["Miscellaneous"] }
    end

    def touch_media
      media_with_inheritance.touch_all
    end

    def touch_lessons
      lessons.touch_all
    end

    def touch_siblings(_lesson)
      lessons.touch_all
      Medium.where(teachable: lessons).touch_all
    end

    def touch_chapters
      chapters.touch_all
    end

    def touch_sections
      Section.where(chapter: chapters).touch_all
    end

    def destroy_forum
      return unless forum

      forum.destroy
    end

    def term_independent?
      return false unless course

      course.term_independent
    end

    def absence_of_term
      return unless term

      errors.add(:term, :present)
    end

    def only_one_lecture
      return unless Lecture.where(course: course).any?

      errors.add(:course, :already_present)
    end

    def older_than?(timespan)
      return false unless Term.active
      return true unless term

      term.begin_date <= Term.active.begin_date - timespan
    end

    def tutorial_ids_for_tutor(tutor)
      TutorTutorialJoin.where(tutor: tutor).select(:tutorial_id)
    end

    def talk_ids_for_speaker(speaker)
      SpeakerTalkJoin.where(speaker: speaker).select(:talk_id)
    end
end
