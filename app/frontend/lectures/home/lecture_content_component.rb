# Shows what the lecture is about on its home page, next to the organizational
# blocks: the last session, new media and how far the lecture has come while
# it runs, and an overview of chapters and materials once it is over.
class LectureContentComponent < ViewComponent::Base
  # A lecture without a session for this long counts as over for its term.
  RECENT = 3.weeks

  # The sidebar's projects offered for revision, with the media sort they count.
  REVISION_PROJECTS = [
    ["script", "Script", :lecture_script_path],
    ["lesson_material", "LessonMaterial", :lecture_lesson_materials_path],
    ["quiz", "Quiz", :lecture_quizzes_path],
    ["repetition", "Repetition", :lecture_repetitions_path]
  ].freeze

  Revision = Struct.new(:label, :path, keyword_init: true)
  MediumLink = Struct.new(:label, :path, :icon, keyword_init: true)

  attr_reader :lecture, :user

  def initialize(lecture:, user:)
    super()
    @lecture = lecture
    @user = user
  end

  def render?
    mode.present?
  end

  # :live while sessions are recent, :over once they stopped in a running term,
  # :archive for a past term, :contents for a running lecture that keeps no
  # sessions, only an outline; nil when there is nothing to show.
  def mode
    return @mode if defined?(@mode)

    @mode = if term_over?
      :archive if lessons.any? || chapters.any?
    elsif lessons.empty?
      chapters.any? ? :contents : (:live if new_media.any?)
    elsif last_lesson.date >= RECENT.ago.to_date
      :live
    else
      :over
    end
  end

  def live?
    mode == :live
  end

  def last_lesson
    lessons.last
  end

  def last_lesson_title
    last_lesson.sections.map { |section| "#{section.displayed_number} #{section.title}" }
               .join(", ")
  end

  def last_lesson_tags
    last_lesson.tags.map(&:title).first(4).join(" · ")
  end

  # Names a session's notes and videos by their kind, and adds the medium's
  # name once the session has several to tell apart.
  def last_lesson_links
    media = last_lesson.visible_media(user)
    media.flat_map do |medium|
      name = medium.description.presence || medium.local_title_for_viewers unless media.one?
      links = []
      if medium.manuscript.present?
        links << medium_link(name, :notes, helpers.display_medium_path(medium),
                             "bi-file-earmark-text")
      end
      if medium.video.present?
        links << medium_link(name, :video, helpers.play_medium_path(medium), "bi-play-circle")
      end
      links
    end
  end

  # A notification outlives a medium being hidden again, so each one is
  # checked the way the medium's own page checks it.
  def new_media
    @new_media ||= Medium.where(id: user.active_media_notifications(lecture)
                                        .select(:notifiable_id))
                         .order(created_at: :desc)
                         .select { |medium| medium.visible_for_user?(user) }
  end

  def current_section
    @current_section ||= all_sections.select { |section| section.in?(last_lesson.sections) }
                                     .max_by { |section| all_sections.index(section) }
  end

  def section_progress
    return @section_progress if @section_progress

    reached = all_sections.index(current_section)
    @section_progress = all_sections.each_with_index.map do |section, index|
      [section, progress_state(index, reached)]
    end
  end

  def overview_key
    case mode
    when :archive then lecture.term.to_label
    when :contents then t("lecture_home.content.contents")
    else t("lecture_home.content.over")
    end
  end

  def overview_title
    return t("lecture_home.content.chapters", count: chapters.size) if lessons.empty?

    first = l(lessons.first.date, format: :day_month)
    last = l(last_lesson.date, format: :day_month)
    return t("lecture_home.content.one_lesson", date: first) if lessons.one?

    t("lecture_home.content.lessons", count: lessons.size, from: first, to: last)
  end

  def chapters
    @chapters ||= lecture.chapters.includes(:sections).to_a
  end

  # Names the sections of a chapter, unless it has one that only repeats its
  # title.
  def section_list(chapter)
    sections = chapter.sections.to_a
    return if sections.one? && sections.first.title == chapter.title

    sections.map { |section| "#{section.displayed_number} #{section.title}" }.join(", ")
            .presence
  end

  def chapter_label(chapter)
    "#{chapter.displayed_number}. #{chapter.title}"
  end

  def chapter_summary(chapter)
    count = t("lecture_home.content.sections", count: chapter.sections.size)
    "#{chapter_label(chapter)} · #{count}"
  end

  def progress_label
    reached = section_progress.index { |_, state| state == :now } + 1
    t("lecture_home.content.progress", reached: reached, total: section_progress.size)
  end

  def new_media_links
    links = new_media.first(2).map do |medium|
      helpers.link_to(medium.local_title_for_viewers, helpers.medium_path(medium))
    end
    helpers.safe_join(links, ", ")
  end

  def revision_links
    links = revisions.map do |revision|
      helpers.link_to(revision.label, revision.path, data: { turbo_frame: "main" })
    end
    helpers.safe_join(links, " · ")
  end

  def revisions
    @revisions ||= REVISION_PROJECTS.filter_map do |project, sort, path|
      next unless lecture.public_send(:"#{project}?", user)

      count = visible_media_count(sort)
      label = t("categories.#{project}.#{count > 1 ? "plural" : "singular"}",
                default: t("categories.#{project}.singular"))
      label = "#{label} (#{count})" if count > 1
      Revision.new(label: label, path: helpers.public_send(path, lecture))
    end
  end

  def revisions_key
    mode == :over ? t("lecture_home.content.revision") : t("lecture_home.content.materials")
  end

  private

    def medium_link(name, kind, path, icon)
      label = [name, t("lecture_home.content.#{kind}")].compact.join(" · ")
      MediumLink.new(label: label, path: path, icon: icon)
    end

    def progress_state(index, reached)
      return :done if index < reached
      return :now if index == reached

      :open
    end

    def term_over?
      lecture.term.present? && lecture.term.end_date < Date.current
    end

    def lessons
      @lessons ||= lecture.lessons.includes(:tags, sections: :chapter).to_a
    end

    def all_sections
      @all_sections ||= chapters.flat_map(&:sections)
    end

    def visible_media_count(sort)
      Medium.proper.where(teachable: [lecture, *lessons], sort: sort)
            .count { |medium| medium.visible_for_user?(user) }
    end
end
