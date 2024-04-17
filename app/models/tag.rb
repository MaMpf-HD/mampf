# Tag class
class Tag < ApplicationRecord
  # a tag appears in many courses
  has_many :course_tag_joins, dependent: :destroy
  has_many :courses, through: :course_tag_joins

  # a tag appears in many lessons
  has_many :lesson_tag_joins, dependent: :destroy
  has_many :lessons, through: :lesson_tag_joins

  # a tag appears in many talks
  has_many :talk_tag_joins, dependent: :destroy
  has_many :talks, through: :talk_tag_joins

  # a tag appears in many sections
  has_many :section_tag_joins, dependent: :destroy
  has_many :sections, through: :section_tag_joins

  # a tag appears in many media
  # a tag appears in many media
  has_many :medium_tag_joins, dependent: :destroy
  has_many :media, through: :medium_tag_joins

  # a tag has many related tags
  has_many :relations, dependent: :destroy
  # an update of the related tags only triggers a deletion of the relation
  # join table entry, but we need it to be destroyed as there is
  # the symmetrization callback on relations
  has_many :related_tags, through: :relations, after_remove: :destroy_relations

  # a tag has different notions in different languages
  has_many :notions,
           after_remove: :touch_relations,
           after_add: :touch_relations,
           dependent: :destroy,
           inverse_of: :tag
  has_many :aliases,
           foreign_key: "aliased_tag_id",
           class_name: "Notion",
           inverse_of: :aliased_tag

  serialize :realizations, Array

  accepts_nested_attributes_for :notions,
                                reject_if: lambda { |attributes|
                                             attributes["title"].blank?
                                           },
                                allow_destroy: true

  validates :notions, presence: true
  validates_associated :notions

  accepts_nested_attributes_for :aliases,
                                reject_if: lambda { |attributes|
                                             attributes["title"].blank?
                                           },
                                allow_destroy: true

  validates_associated :aliases

  # touch related lectures and sections after saving because lecture tags
  # are cached
  after_save :touch_lectures
  after_save :touch_sections

  searchable do
    text :titles do
      title_join
    end
    integer :course_ids, multiple: true
  end

  def self.find_erdbeere_tags(sort, id)
    Tag.where(id: Tag.pluck(:id, :realizations)
                     .select { |x| [sort, id].in?(x.second) }
                     .map(&:first))
  end

  def title
    Rails.cache.fetch("#{cache_key_with_version}/title") do
      local_title_uncached
    end
  end

  def extended_title_uncached
    return local_title_uncached unless other_titles_uncached.any? || aliases.any?
    return local_title_uncached + " (#{other_titles_uncached.join(", ")})" unless aliases.any?
    unless other_titles_uncached.any?
      return local_title_uncached + " (#{aliases.pluck(:title).join(", ")})"
    end

    local_title_uncached +
      " (#{aliases.pluck(:title).join(", ")}, " \
      "#{other_titles_uncached.join(", ")})"
  end

  def extended_title
    Rails.cache.fetch("#{cache_key_with_version}/extended_title") do
      extended_title_uncached
    end
  end

  def locales
    notions.pluck(:locale)
  end

  def local_title_uncached
    notions.find { |n| n.locale == I18n.locale.to_s }&.title ||
      notions.find { |n| n.locale == I18n.default_locale.to_s }&.title ||
      notions.first&.title
  end

  def other_titles_uncached
    notions.pluck(:title) - [local_title_uncached]
  end

  def other_titles
    Rails.cache.fetch("#{cache_key_with_version}/other_titles") do
      other_titles_uncached
    end
  end

  def title_id_hash
    Rails.cache.fetch("#{cache_key_with_version}/title_id_hash") do
      { title: local_title_uncached, id: id }
    end
  end

  def extended_title_id_hash
    Rails.cache.fetch("#{cache_key_with_version}/extended_title_id_hash") do
      { title: extended_title_uncached, id: id }
    end
  end

  def locale_title_hash
    notions.to_h { |n| [n.locale, n.title] }
  end

  def self.select_with_substring(search_string)
    return {} unless search_string
    return {} unless search_string.length >= 2

    search = Sunspot.new_search(Tag)
    search.build do
      fulltext(search_string)
    end
    search.execute
    search.results
          .map { |t| { value: t.id, text: t.title } }
  end

  # returns all tags whose title is close to the given search string
  # wrt to the JaroWinkler metric
  def self.similar_tags(search_string)
    jarowinkler = FuzzyStringMatch::JaroWinkler.create(:pure)
    Tag.where(id: Tag.all.select do |t|
                    jarowinkler.getDistance(t.title.downcase,
                                            search_string.downcase) > 0.9
                  end
                  .map(&:id))
  end

  def self.select_by_title_cached
    Rails.cache.fetch("tag_select_by_title_#{I18n.locale}") do
      Tag.select_by_title.map { |t| { value: t[1], text: t[0] } }.to_json
    end
  end

  # returns the array of all tags (sorted by title) together with
  # their ids
  def self.select_by_title
    Tag.all.map(&:extended_title_id_hash)
       .natural_sort_by { |t| t[:title] }.map { |t| [t[:title], t[:id]] }
  end

  # returns the array of all tags (sorted by title) excluding a given
  # arel of tags together with
  def self.select_by_title_except(excluded_tags)
    Tag.where.not(id: excluded_tags.pluck(:id))
       .map(&:extended_title_id_hash)
       .natural_sort_by { |t| t[:title] }.map { |t| [t[:title], t[:id]] }
  end

  # converts the subgraph of all tags of distance <= 2 to the given marked tag
  # into a cytoscape array representing this subgraph
  def self.to_cytoscape(tags, marked_tag, highlight_related_tags: true)
    # add vertices
    result = tags.map do |t|
      { data: t.cytoscape_vertex(marked_tag, highlight_related_tags: highlight_related_tags) }
    end

    # add edges
    edges = []
    tags.each do |t|
      (t.related_tags & tags).each do |r|
        edges.push([t.id, r.id])
        result.push(data: t.cytoscape_edge(r)) unless [r.id, t.id].in?(edges)
      end
    end
    result
  end

  def realizations_cached
    Rails.cache.fetch("#{cache_key_with_version}/realizations") do
      realizations
    end
  end

  # returns the ARel of all tags or whose id is among a given array of ids
  # search params is a hash having keys :all_tags, :tag_ids
  def self.search_tags(search_params)
    return Tag.all unless search_params[:all_tags] == "0"

    tag_ids = search_params[:tag_ids] || []
    Tag.where(id: tag_ids)
  end

  # returns the array of all tags related to the tags in the given array
  def self.related_tags(tags)
    tags.map(&:related_tags).flatten.uniq
  end

  # lectures that do not belong to courses the tag is associated to
  # but are associated to the given tag
  def extra_lectures
    Lecture.where.not(course: courses).select { |l| in?(l.tags) }
  end

  # lectures that belong to courses the tag is associated to
  # but are not associated to the given tag
  def missing_lectures
    Lecture.where(course: courses).reject { |l| in?(l.tags) }
  end

  # tags of distance <=2 form the given tag
  def tags_in_neighbourhood
    ids = related_tags.map { |t| t.related_tags.pluck(:id) }.flatten.uniq
    related_ids = related_tags.pluck(:id) + [id]
    Tag.where(id: ids - related_ids)
  end

  def short_title(max_letters = 30)
    return title unless title.length > max_letters

    "#{title[0, max_letters - 3]}..."
  end

  def in_lecture?(lecture)
    in?(lecture.tags)
  end

  def in_lectures?(lectures)
    lectures.any? { |l| in_lecture?(l) }
  end

  def in_course?(course)
    in?(course.tags)
  end

  def in_courses?(courses)
    courses.any? { |c| in_course?(c) }
  end

  # returns the ARel of lectures the tag is associated to
  def lectures
    Lecture.where(id: Lecture.all.select { |l| in_lecture?(l) }.map(&:id))
  end

  def create_random_quiz!(user)
    questions = visible_questions(user)
    return unless questions.any?

    question_ids = questions.pluck(:id).sample(5)
    quiz_graph = QuizGraph.build_from_questions(question_ids)

    quiz_i18n = I18n.t("categories.randomquiz.singular")
    quiz = Quiz.new(description: "#{quiz_i18n} #{title} #{Time.zone.now}",
                    level: 1,
                    quiz_graph: quiz_graph,
                    sort: "RandomQuiz")
    quiz.save
    return quiz.errors unless quiz.valid?

    quiz
  end

  # returns the vertex title color of the tag in the neighbourhood graph of
  # the given marked tag
  def color(marked_tag, highlight_related_tags: true)
    return "#f00" if self == marked_tag
    return "#ff8c00" if highlight_related_tags && in?(marked_tag.related_tags)

    "#000"
  end

  # returns the vertex color of the tag in the neighbourhood graph of
  # the given marked tag
  def background(marked_tag, highlight_related_tags: true)
    return "#f00" if self == marked_tag
    return "#ff8c00" if highlight_related_tags && in?(marked_tag.related_tags)

    "#666"
  end

  # returns the cytoscape hash describing the tag's vertex in the neighbourhood
  # graph of the marked tag
  def cytoscape_vertex(marked_tag, highlight_related_tags: true)
    { id: id.to_s,
      label: title,
      color: color(marked_tag,
                   highlight_related_tags: highlight_related_tags),
      background: background(marked_tag,
                             highlight_related_tags: highlight_related_tags) }
  end

  # returns the cytoscape hash describing the edge between the tag and the
  # related tag
  def cytoscape_edge(related_tag)
    { id: "#{id}-#{related_tag.id}",
      source: id,
      target: related_tag.id }
  end

  # published sections are sections that belong to a published lecture
  def visible_sections(user)
    user.filter_sections(sections).select do |s|
      s.lecture.visible_for_user?(user)
    end
  end

  def cache_key
    "#{super}-#{I18n.locale}"
  end

  def touch_lectures
    Lecture.where(id: sections.map { |section| section.lecture.id }).touch_all
  end

  def touch_sections
    sections.touch_all
  end

  def touch_chapters
    Chapter.where(id: sections.map { |section| section.chapter.id }).touch_all
  end

  def identify_with!(tag)
    courses << (tag.courses - courses)
    lessons << (tag.lessons - lessons)
    sections << (tag.sections - sections)
    media << (tag.media - media)
    related_tags << (tag.related_tags - related_tags)
    related_tags.delete(tag)
    tag.sections.each do |s|
      next unless in?(s.tags)

      old_section_tag = SectionTagJoin.find_by(section: s, tag: tag)
      position = old_section_tag.tag_position
      new_section_tag = SectionTagJoin.find_by(section: s, tag: self)
      new_section_tag.insert_at(position)
      old_section_tag.move_to_bottom
    end
    tag.aliases.update(aliased_tag_id: id)
  end

  def common_titles(tag)
    result = { contradictions: [] }
    I18n.available_locales.each do |l|
      result[l] = [locale_title_hash[l.to_s]] + [tag.locale_title_hash[l.to_s]]
      result[l].delete(nil)
      result[:contradictions].push(l) if result[l].count > 1
      result.delete(l) if result[l].blank?
    end
    result
  end

  def visible_questions(user)
    user.filter_visible_media(user.filter_media(media.where(type: "Question")))
  end

  private

    def touch_relations(_notion)
      return unless persisted?

      touch
      touch_lectures
      touch_sections
      touch_chapters
    end

    # simulates the after_destroy callback for relations
    def destroy_relations(related_tag)
      Relation.where(tag: [self, related_tag],
                     related_tag: [self, related_tag]).delete_all
    end

    def title_join
      result = notions.pluck(:title).join(" ")
      return result unless aliases.any?

      "#{result} #{aliases.pluck(:title).join(" ")}"
    end
end
