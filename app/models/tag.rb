# Tag class
class Tag < ApplicationRecord
  # a tag appears in many courses
  has_many :course_tag_joins, dependent: :destroy
  has_many :courses, through: :course_tag_joins

  # a tag appears in many lessons
  has_many :lesson_tag_joins, dependent: :destroy
  has_many :lessons, through: :lesson_tag_joins

  # a tag appears in many sections
  has_many :section_tag_joins, dependent: :destroy
  has_many :sections, through: :section_tag_joins

  # a tag appears in many media
  has_many :medium_tag_joins, dependent: :destroy
  has_many :media, through: :medium_tag_joins

  # a tag has many related tags
  has_many :relations, dependent: :destroy
  # an update of the related tags only triggers a deletion of the relation
  # join table entry, but we need it to be destroyed as there is
  # the symmetrization callback on relations
  has_many :related_tags, through: :relations, after_remove: :destroy_relations

  # a tag needs to have a unique title
  validates :title, presence: { message: 'Es muss ein Titel angegeben ' \
                                         'werden.' },
                    uniqueness: { message: 'Titel ist bereits vergeben.' }

  # touch related lectures and sections after saving because lecture tags
  # are cached
  after_save :touch_lectures
  after_save :touch_sections

  # remove tag from all section tag orderings
  # execute this callback before all others, as otherwise associated sections
  # will already have been deleted
  before_destroy :remove_from_section_tags_order, prepend: true

  def self.ids_titles_json
    Tag.order(:title).map { |t| { id: t.id, title: t.title } }.to_json
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

  # returns the array of all tags (sorted by title) together with
  # their ids
  def self.select_by_title
    Tag.pluck(:title,:id).map { |title, id| { title: title, id: id } }
       .natural_sort_by{ |t| t[:title] }.map { |t| [t[:title], t[:id]] }
  end

  # returns the array of all tags (sorted by title) excluding a given
  # arel of tags together with
  def self.select_by_title_except(excluded_tags)
    Tag.where.not(id: excluded_tags.pluck(:id)).pluck(:title, :id)
       .map { |title, id| { title: title, id: id } }
       .natural_sort_by{ |t| t[:title] }.map { |t| [t[:title], t[:id]] }
  end

  # converts the subgraph of all tags of distance <= 2 to the given marked tag
  # into a cytoscape array representing this subgraph
  def self.to_cytoscape(tags, marked_tag)
    result = []
    # add vertices
    tags.each do |t|
      result.push(data: t.cytoscape_vertex(marked_tag))
    end
    # add edges
    tags.each do |t|
      (t.related_tags & tags).each do |r|
        result.push(data: t.cytoscape_edge(r))
      end
    end
    result
  end

  # returns the ARel of all tags or whose id is among a given array of ids
  # search params is a hash having keys :all_tags, :tag_ids
  def self.search_tags(search_params)
    return Tag.all unless search_params[:all_tags] == '0'
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
    title[0, max_letters - 3] + '...'
  end

  def in_lecture?(lecture)
    in?(lecture.tags)
  end

  def in_lectures?(lectures)
    lectures.any? { |l| in_lecture?(l) }
  end

  # returns the ARel of lectures the tag is associated to
  def lectures
    Lecture.where(id: Lecture.all.select { |l| in_lecture?(l) }.map(&:id))
  end

  # returns the vertex title color of the tag in the neighbourhood graph of
  # the given marked tag
  def color(marked_tag)
    return '#f00' if self == marked_tag
    return '#ff8c00' if in?(marked_tag.related_tags)
    '#000'
  end

  # returns the vertex color of the tag in the neighbourhood graph of
  # the given marked tag
  def background(marked_tag)
    return '#f00' if self == marked_tag
    return '#ff8c00' if in?(marked_tag.related_tags)
    '#666'
  end

  # returns the cytoscape hash describing the tag's vertex in the neighbourhood
  # graph of the marked tag
  def cytoscape_vertex(marked_tag)
    { id: id.to_s,
      label: title,
      color: color(marked_tag),
      background: background(marked_tag) }
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
    user.filter_sections(sections).select { |s| s.lecture.visible_for_user?(user) }
  end

  private

  def touch_lectures
    sections.map(&:lecture).uniq.each(&:touch)
  end

  def touch_sections
    sections.update_all updated_at: Time.now
  end

  # simulates the after_destroy callback for relations
  def destroy_relations(related_tag)
    Relation.where(tag: [self, related_tag],
                   related_tag: [self, related_tag]).delete_all
  end

  def remove_from_section_tags_order
    sections.each do |s|
      s.update(tags_order: s.tags_order - [id])
    end
  end
end
