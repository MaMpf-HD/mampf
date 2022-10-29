# Manuscript class
# plain old ruby class, no active record involved
class Manuscript
  include ActiveModel::Model

  attr_reader :medium, :lecture, :chapters, :sections, :content,
              :contradictions, :contradiction_count, :count,
              :content_descriptions, :version

  def initialize(medium)
    unless medium && medium.sort == 'Script' &&
           medium&.teachable_type == 'Lecture' &&
           medium.manuscript
      return
    end
    @medium = medium
    @lecture = medium.teachable.lecture
    @version = medium.manuscript.metadata['version']
    bookmarks = medium.manuscript.metadata['bookmarks'] || []
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
    @lecture&.chapters
            &.find { |chap| chap.reference == chapter['label'] }
  end

  def section_in_mampf(section)
    @lecture&.sections_cached
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
    destinations = @chapters.map { |c| c['destination'] } - ['']
    items = Item.where(medium: @medium,
                       pdf_destination: destinations,
                       sort: 'chapter')
    item_id_map = items.pluck(:pdf_destination, :id).to_h
    item_destinations = item_id_map.keys
    attrs = %i(medium_id pdf_destination section_id sort page
               description ref_number position quarantine)
    item_details = items.pluck(*attrs).map { |i| attrs.zip(i).to_h }
    contents = []
    @chapters.each do |c|
      contents.push(
        { medium_id: @medium.id,
          pdf_destination: c['destination'],
          section_id: nil,
          sort: 'chapter',
          page: c['page'].to_i,
          description: c['description'],
          ref_number: c['label'],
          position: nil,
          quarantine: nil })
    end
    create_or_update_items!(contents, item_details, item_destinations,
                            item_id_map)
  end

  def create_or_update_section_items!
    destinations = @sections.map { |s| s['destination'] } - ['']
    items = Item.where(medium: @medium,
                       pdf_destination: destinations,
                       sort: 'section')
    item_id_map = items.pluck(:pdf_destination, :id).to_h
    item_destinations = item_id_map.keys
    attrs = %i(medium_id pdf_destination section_id sort page
               description ref_number position quarantine)
    item_details = items.pluck(*attrs).map { |i| attrs.zip(i).to_h }
    contents = []
    # note that sections get a position -1 in order to place them ahead
    # of all content items within themseleves in #script_items_by_position
    @sections.each do |s|
      contents.push(
        { medium_id: @medium.id,
          pdf_destination: s['destination'],
          section_id: s['mampf_section'].id,
          sort: 'section',
          page: s['page'].to_i,
          description: s['description'],
          ref_number: s['label'],
          position: -1,
          quarantine: nil })
    end
    create_or_update_items!(contents, item_details, item_destinations,
                            item_id_map)
  end

  # creates/updates items for the manuscript content as specified by the user
  # in filter_boxes (which basically contains the information on whichk
  # content checkboxes have been checked)
  def create_or_update_content_items!(filter_boxes)
    destinations = @content.map { |c| c['destination'] } - ['']
    items = Item.where(medium: @medium,
                       pdf_destination: destinations)
    item_id_map = items.pluck(:pdf_destination, :id).to_h
    item_destinations = item_id_map.keys
    attrs = %i(medium_id pdf_destination section_id sort page
               description ref_number position hidden quarantine)
    item_details = items.pluck(*attrs).map { |i| attrs.zip(i).to_h }
    contents = []
    @content.each do |c|
      contents.push(
        { medium_id: @medium.id,
          pdf_destination: c['destination'],
          section_id: @sections.find do |s|
                        c['section'] == s['section']
                      end ['mampf_section']&.id,
          sort: Item.internal_sort(c['sort']),
          page: c['page'].to_i,
          description: c['description'],
          ref_number: c['label'],
          position: c['counter'],
          hidden: filter_boxes[c['counter']].third == false,
          quarantine: nil })
    end
    create_or_update_items!(contents, item_details, item_destinations,
                            item_id_map)
  end

  def create_or_update_items!(contents, item_details, item_destinations,
                              item_id_map)
    different_contents = contents - item_details
    new_contents = different_contents.reject do |c|
      c[:pdf_destination].in?(item_destinations)
    end
    new_items = new_contents.map { |c| Item.new(c) }
    Item.import new_items, validate: false
    new_item_ids = Item.where(medium: @medium,
                              pdf_destination: new_items.pluck(:pdf_destination))
                       .pluck(:id)
    @medium.item_ids << new_item_ids
    changed_contents = different_contents - new_contents
    changed_contents.each do |c|
      Item.find_by_id(item_id_map[c[:pdf_destination]])
          .update(c)
    end
  end

  # creates tags for the manuscript content as specified by the user
  # in filter_boxes (which basically contains the information on which
  # content checkboxes have been checked)
  # updates section and course info for already existin tags (tags will
  # be associated with the course of the manuscript's lecture)
  def update_tags!(filter_boxes)
    sections_with_content.each do |s|
      section = s['mampf_section']
      content_in_section(s).each do |c|
        # if tag for content already exists, add tag to the section and course
        if c['tag_id']
          tag = Tag.find_by_id(c['tag_id'])
          next unless tag
          next unless section
          next if section.in?(tag.sections)
          tag.sections |= [section]
          tag.courses |= [@lecture.course]
          next
        end
        next unless filter_boxes[c['counter']].second
        # if checkbox for tag creation is checked, create the tag,
        # associate it with course and section
        tag = Tag.new(courses: [@lecture.course],
                      sections: [section])
        tag.notions.new(title: c['description'],
                        locale: @lecture.locale || I18n.default_locale)
        tag.save
      end
    end
  end

  # pdf destinations as extracted from pdf metadata
  def destinations
    bookmarks = @medium.manuscript.metadata['bookmarks'] || []
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
    desc_hash = Notion.where(locale: @lecture.locale || I18n.default_locale)
                      .pluck(:title, :tag_id, :aliased_tag_id)
                      .map { |x| [x.first.downcase, x.second || x.third] }
                      .select { |x| x.first.in?(@content_descriptions.map(&:downcase)) }
                      .to_h
    @content.each do |c|
      c['tag_id'] = desc_hash[c['description'].downcase]
    end
  end

  # add information on the item ids for manuscript content and hidden status
  def add_info_on_item_ids_and_hidden_status
    destinations = @content.map { |c| c['destination'] } - ['']
    items_hash = Item.where(medium: @medium,
                            pdf_destination: destinations)
                     .pluck(:pdf_destination, :id, :hidden)
                     .map { |c| [c[0], [c[1], c[2]]] }.to_h
    @content.each do |c|
      c['item_id'] = items_hash[c['destination']]&.first
      c['hidden'] = items_hash[c['destination']]&.second
    end
  end

#  private

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
      'multiplicities' => destinations_with_higher_multiplicities,
      'version' => version_info }
  end

  def determine_contradiction_count
    @contradictions['chapters'].size + @contradictions['sections'].size +
      @contradictions['content'].size + @contradictions['multiplicities'].size +
      @contradictions['version'].size
  end

  def version_info
    return [] if @version == DefaultSetting::MAMPF_STY_VERSION
    [@version.to_s]
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
    Notion.where(locale: @lecture.locale || I18n.default_locale)
          .pluck('title') & @content_descriptions
  end
end
