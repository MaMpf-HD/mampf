# Manuscript class
# plain old ruby class, no active record involved
class Manuscript
  include ActiveModel::Model

  attr_reader :medium, :lecture, :chapters, :sections, :content,
              :contradictions, :contradiction_count, :count,
              :content_descriptions

  def initialize(medium)
    unless medium && medium.sort == 'Script' &&
           medium&.teachable_type == 'Lecture' &&
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
    @content_descriptions = @content.map { |c| c['description'] } - ['']
    add_info_on_tag_ids
    add_info_on_item_ids_and_hidden_status
    @contradictions = determine_contradictions
    @contradiction_count = determine_contradiction_count
    @count = bookmarks.count
  end

  def empty?
    @medium.nil?
  end

  def sections_in_chapter(chapter)
    @sections.select { |s| s['chapter'] == chapter['chapter'] }
             .sort_by { |s| s['counter'] }
  end

  def content_in_section(section)
    @content.select { |c| c['section'] == section['section'] }
            .sort_by { |c| c['counter'] }
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
    @lecture&.chapters&.includes(:lecture)
            &.find { |chap| chap.reference == chapter['label'] }
  end

  def section_in_mampf(section)
    @lecture&.sections
            &.find { |sec| sec.reference == section['label'] }
  end

  # returns if the mampf chapter for the corresponding chapter has a different
  # title
  def manuscript_chapter_contradicts?(chapter)
    chapter_in_mampf(chapter)&.title != chapter['description']
  end

  # export manuscript to database:
  # - creates new chapters and sections if necessary
  # - creates items for new chapters and sections
  # - creates items and tags for new content, depending on the users choices
  def export_to_db!(filter_boxes)
    return unless @contradiction_count.zero?
    create_new_chapters!
    @chapters.each do |c|
      create_new_sections!(c)
      c['mampf_chapter'] = c['mampf_chapter'].reload
    end
    create_or_update_chapter_items!
    create_or_update_section_items!
    create_or_update_content_items!(filter_boxes)
    update_tags!(filter_boxes)
  end

  # chapters in mampf that are not represented in the manuscript
  def unmatched_mampf_chapters
    chapters_in_mampf = @chapters.map { |c| c['mampf_chapter'] }.compact
    @lecture.chapters - chapters_in_mampf
  end

  def unmatched_mampf_sections
    sections_in_mampf = @sections.map { |s| s['mampf_section'] }.compact
    @lecture.sections - sections_in_mampf
  end

  # create chapters in mampf for those manuscript chapters not yet in mampf
  def create_new_chapters!
    new_chapters.each do |c|
      chap = Chapter.new(lecture_id: @lecture.id, title: c.second)
      chap.insert_at(c.first)
      corresponding = @chapters.find { |d| d['counter'] == c.third }
      corresponding['mampf_chapter'] = chap
    end
    @lecture = @lecture.reload
  end

  # create sections in mampf for those manuscript sections not yet in mampf
  def create_new_sections!(chapter)
    return if chapter['mampf_chapter'].nil?
    mampf_chapter = chapter['mampf_chapter']
    new_sections_in_chapter(chapter).each do |s|
      sect = Section.new(chapter_id: mampf_chapter.id, title: s.second)
      sect.insert_at(s.first)
      corresponding = @sections.find { |d| d['counter'] == s.third }
      corresponding['mampf_section'] = sect
    end
  end

  def create_or_update_chapter_items!
    @chapters.each do |c|
      # check if there exists an item with this pdf destination in this medium
      # if so, only update if necessary
      items = Item.where(medium: @medium,
                         pdf_destination: c['destination'])
      if items.any?
        next if items.exists?(sort: 'chapter',
                              page: c['page'],
                              description: c['description'],
                              ref_number: c['label'],
                              position: nil,
                              section_id: nil,
                              start_time: nil,
                              quarantine: false)
        items.first.update(sort: 'chapter',
                           page: c['page'],
                           description: c['description'],
                           ref_number: c['label'],
                           position: nil,
                           section_id: nil,
                           start_time: nil,
                           quarantine: false)
        next
      end
      Item.create(medium_id: @medium.id,
                  section_id: nil,
                  sort: 'chapter',
                  page: c['page'],
                  description: c['description'],
                  ref_number: c['label'],
                  pdf_destination: c['destination'])
    end
  end

  def create_or_update_section_items!
    @sections.each do |s|
      # check if there exists an item with this pdf destination in this medium
      # if so, only update if necessary
      items = Item.where(medium: @medium,
                         pdf_destination: s['destination'])

      if items.any?
        next if items.exists?(section_id: s['mampf_section'].id,
                              sort: 'section',
                              page: s['page'],
                              description: s['description'],
                              ref_number: s['label'],
                              position: -1,
                              start_time: nil,
                              quarantine: false)
        items.first.update(section_id: s['mampf_section'].id,
                           sort: 'section',
                           page: s['page'],
                           description: s['description'],
                           ref_number: s['label'],
                           position: -1,
                           start_time: nil,
                           quarantine: false)
        next
      end
      # note that sections get a position -1 in order to place them ahead
      # of all content items within themseleves in #script_items_by_position
      Item.create(medium_id: @medium.id,
                  section_id: s['mampf_section'].id,
                  sort: 'section',
                  page: s['page'],
                  description: s['description'],
                  ref_number: s['label'],
                  pdf_destination: s['destination'],
                  position: -1)
    end
  end

  # creates/updates items for the manuscript content as specified by the user
  # in filter_boxes (which basically contains the information on whichk
  # content checkboxes have been checked)
  def create_or_update_content_items!(filter_boxes)
    new_items = []
    sections_with_content.each do |s|
      content_in_section(s).each do |c|
        # check if there exists an item with this pdf destination in this medium
        # if so, only update if necessary
        hidden = filter_boxes[c['counter']].third == false
        items = Item.where(medium: @medium,
                           pdf_destination: c['destination'])
        if items.any?
          next if items.exists?(section_id: s['mampf_section'].id,
                                sort: Item.internal_sort(c['sort']),
                                page: c['page'], description: c['description'],
                                ref_number: c['label'], position: c['counter'],
                                start_time: nil,
                                quarantine: false,
                                hidden: hidden)
          items.first.update(section_id: s['mampf_section'].id,
                             sort: Item.internal_sort(c['sort']),
                             page: c['page'], description: c['description'],
                             ref_number: c['label'], position: c['counter'],
                             start_time: nil,
                             quarantine: false,
                             hidden: hidden)
          next
        end
        new_items.push Item.new(medium_id: @medium.id,
                                section_id: s['mampf_section'].id,
                                sort: Item.internal_sort(c['sort']),
                                page: c['page'],
                                description: c['description'],
                                ref_number: c['label'],
                                position: c['counter'],
                                pdf_destination: c['destination'],
                                hidden: hidden)
      end
    end
    # in contrast to section items and chapter items, this one uses
    # the activerecord-import gem which does it with fewer SQL-queries
    # (however, no validations seem to be performed even though the
    # corresponding flag is set)
    Item.import new_items, validate: true
    @medium.touch
  end

  # creates tags for the manuscript content as specified by the user
  # in filter_boxes (which basically contains the information on whichk
  # content checkboxes have been checked)
  # updates section and course info for already existin tags (tags will
  # be associated with the course of the manuscript's lecture)
  def update_tags!(filter_boxes)
    sections_with_content.each do |s|
      content_in_section(s).each do |c|
        section = s['mampf_section']
        # if tag for content already exists, add tag to the section and course
        if c['tag_id']
          tag = Tag.find_by_id(c['tag_id'])
          next unless tag
          next unless section
          next if section.in?(tag.sections)
          tag.sections |= [section]
          section.update(tags_order: section.tags_order + [tag.id])
          tag.courses |= [@lecture.course]
          next
        end
        next unless filter_boxes[c['counter']].second
        # if checkbox for tag creation is checked, create the tag,
        # associate it with course and section
        tag = Tag.create(title: c['description'], courses: [@lecture.course],
                         sections: [section])
        section.update(tags_order: section.tags_order +  [tag.id])
      end
    end
  end

  # pdf destinations as extracted from pdf metadata
  def destinations
    bookmarks = @medium.manuscript[:original].metadata['bookmarks'] || []
    bookmarks.map { |b| b['destination'] }
  end

  # pdf destinations together with their multiplicity
  # (something is wrong if a pdf destination has a multiplicity higher than one)
  def destinations_with_multiplicities
    destinations.each_with_object(Hash.new(0)) do |word, counts|
      counts[word] += 1
    end
  end

  def destinations_with_higher_multiplicities
    destinations_with_multiplicities.select { |_k, v| v > 1 }.keys
  end

  # add information on the tag ids for manuscript content
  def add_info_on_tag_ids
    tags = existing_tags
    @content.each do |c|
      c['tag_id'] = if c['description'].in?(tags)
                      Tag.where(title: c['description'])&.first&.id
                    end
    end
  end

  # add information on the item ids for manuscript content and hidden status
  def add_info_on_item_ids_and_hidden_status
    @content.each do |c|
      item = Item.where(medium: @medium,
                        pdf_destination: c['destination'])&.first
      item_id = item&.id
      c['item_id'] = item_id
      c['hidden'] = item ? item.hidden : nil
    end
  end

  private

  def get_chapters(bookmarks)
    bookmarks.select { |b| b['sort'] == 'Kapitel' }
             .sort_by { |c| c['counter'] }
             .each_with_index { |c, i| c['new_position'] = i + 1 }
  end

  def get_sections(bookmarks)
    bookmarks.select { |b| b['sort'] == 'Abschnitt' }
             .sort_by { |s| s['counter'] }
  end

  def get_content(bookmarks)
    bookmarks.reject { |b| b['sort'].in?(['Kapitel', 'Abschnitt']) }
             .sort_by { |c| c['counter'] }
  end

  def match_mampf_chapters
    @chapters.each do |c|
      mampf_chapter = chapter_in_mampf(c)
      c['mampf_chapter'] = mampf_chapter
      c['contradiction'] = if mampf_chapter.nil? ||
                              mampf_chapter.title == c['description']
                             false
                           else
                             :different_title
                           end
    end
  end

  def match_mampf_sections
    @sections.each do |s|
      bookmarked_chapter_counters = @chapters.map { |c| c['chapter'] }
      unless s['chapter'].in?(bookmarked_chapter_counters)
        s['mampf_section'] = nil
        s['contradiction'] = :missing_chapter
        next
      end
      mampf_section = section_in_mampf(s)
      s['mampf_section'] = mampf_section
      s['contradiction'] = if mampf_section.nil? ||
                              mampf_section.title == s['description']
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
      c['contradiction'] = if !c['chapter'].in?(bookmarked_chapter_counters)
                             :missing_chapter
                           elsif !c['section'].in?(bookmarked_section_counters)
                             :missing_section
                           else
                             false
                           end
    end
  end

  def determine_contradictions
    { 'chapters' => @chapters.select { |c| c['contradiction'] },
      'sections' => @sections.select { |s| s['contradiction'] },
      'content' => @content.select { |c| c['contradiction'] },
      'multiplicities' => destinations_with_higher_multiplicities }
  end

  def determine_contradiction_count
    @contradictions['chapters'].size + @contradictions['sections'].size +
      @contradictions['content'].size + @contradictions['multiplicities'].size
  end

  # chapters in the manuscript not represented in mampf
  def new_chapters
    @chapters.select { |c| c['mampf_chapter'].nil? }
             .map { |c| [c['new_position'], c['description'], c['counter']] }
  end

  # sections in a manuscript chapter not represented in mampf
  def new_sections_in_chapter(chapter)
    sections = sections_in_chapter(chapter)
    sections.each_with_index
            .map do |s, i|
              [s['mampf_section'], i + 1, s['description'], s['counter']]
            end
            .select { |s| s.first.nil? }
            .map { |s| [s.second, s.third, s.fourth] }
  end

  def sections_with_content
    @sections.select { |s| content_in_section(s).present? }
  end

  # returns the titles of those tags that are descriptions of content in
  # the manuscript as well
  def existing_tags
    Tag.pluck('title') & @content_descriptions
  end
end
