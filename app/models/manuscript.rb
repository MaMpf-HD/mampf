# Manuscript class
# plain old ruby class, no active record involved
class Manuscript
  include ActiveModel::Model

  attr_reader :medium, :lecture, :chapters, :sections, :content,
              :contradictions, :contradiction_count

  def initialize(medium)
    unless medium.sort == 'Script' && medium&.teachable_type == 'Lecture' &&
             medium.manuscript && medium.manuscript[:original]
      return
    end
    @medium = medium
    @lecture = medium.teachable.lecture
    bookmarks = medium.manuscript[:original].metadata['bookmarks'] || []
    @chapters = get_chapters(bookmarks)
    match_mampf_chapters
    @sections = get_sections(bookmarks)
    match_mampf_sections
    @content = get_content(bookmarks)
    check_content
    @contradictions = get_contradictions
    @contradiction_count = @contradictions['chapters'].size +
                             @contradictions['sections'].size +
                             @contradictions['content'].size
  end

  def sections_in_chapter(chapter)
    @sections.select { |s| s['chapter'] == chapter['chapter'] }
             .sort_by { |s| s['counter'] }
  end

  def content_in_section(section)
    @content.select { |c| c['section'] == section['section'] }
  end

  # returns those content bookmarks who have a chapter or section counter
  # that corresponds to a chapter or section without a bookmark
  def content_in_unbookmarked_locations
    @content.select { |c| c['contradiction'] }
  end

  def content_in_unbookmarked_locations?
    @content.any? { |c| c['contradiction'] }
  end

  def sections_in_unbookmarked_chapters
    @sections.select { |s| s['contradiction'] == :missing_chapter }
  end

  def sections_in_unbookmarked_chapters?
    @sections.any? { |s| s['contradiction'] == :missing_chapter }
  end

  # returns the matching chapter in mampf for the given manuscript chapter
  # (matching is done by label)
  def chapter_in_mampf(chapter)
    @lecture&.chapters
             .find { |chap| chap.reference == chapter['label'] }
  end

  def section_in_mampf(section)
    @lecture&.sections
             .find { |sec| sec.reference == section['label'] }
  end

  def manuscript_chapter_contradicts?(chapter)
    chapter_in_mampf(chapter)&.title != chapter['description']
  end

  def export_to_db!
    return unless @contradiction_count.zero?
  end

  def unmatched_mampf_chapters
    chapters_in_mampf = @chapters.map { |c| c['mampf_chapter'] }.compact
    @lecture.chapters - chapters_in_mampf
  end

  def unmatched_mampf_sections
    sections_in_mampf = @sections.map { |s| s['mampf_section'] }.compact
    @lecture.sections - sections_in_mampf
  end

  private

  def get_chapters(bookmarks)
    bookmarks.select { |b| b['sort'] == 'Kapitel' }
             .map { |c| c.slice('label', 'chapter', 'description', 'counter') }
             .sort_by { |c| c['counter'] }
  end

  def get_sections(bookmarks)
    bookmarks.select { |b| b['sort'] == 'Abschnitt' }
              .map { |s| s.slice('label', 'section', 'description', 'chapter',
                                 'counter') }
              .sort_by { |s| s['counter'] }
  end

  def get_content(bookmarks)
    bookmarks.select { |b| !b['sort'].in?(['Kapitel', 'Abschnitt']) }
             .map { |c| c.slice('sort','label', 'description',
                                'chapter', 'section', 'counter') }
             .sort_by { |c| c['counter'] }
  end

  def match_mampf_chapters
    @chapters.each do |c|
      mampf_chapter = chapter_in_mampf(c)
      c['mampf_chapter'] = mampf_chapter
      c['contradiction'] = if mampf_chapter.nil? || mampf_chapter.title == c['description']
                             false
                           else
                             :different_title
                           end
    end
  end

  def match_mampf_sections
    @sections.each do |s|
      bookmarked_chapter_counters = @chapters.map { |c| c['chapter'] }
      if !s['chapter'].in?(bookmarked_chapter_counters)
        s['mampf_section'] = nil
        s['contradiction'] = :missing_chapter
        next
      end
      mampf_section = section_in_mampf(s)
      s['mampf_section'] = mampf_section
      s['contradiction'] = if mampf_section.nil? || mampf_section.title == s['description']
                             false
                           else
                             :different_title
                           end
    end
  end

  def check_content
    bookmarked_section_counters = @sections.map { |s| s['section'] }
    bookmarked_chapter_counters = @chapters.map { |c| c['chapter'] }
    @content.each do |c|
      if !c['chapter'].in?(bookmarked_chapter_counters)
        c['contradiction'] = :missing_chapter
      elsif !c['section'].in?(bookmarked_section_counters)
        c['contradiction'] = :missing_section
      else
        c['contradiction'] = false
      end
    end
  end

  def get_contradictions
    { 'chapters' => @chapters.select { |c| c['contradiction'] },
      'sections' => @sections.select { |s| s['contradiction'] },
      'content' => @content.select { |c| c['contradiction'] } }
  end
end