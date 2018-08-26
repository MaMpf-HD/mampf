# Graph theoretical methods are no longer necessary uncomment them if they are
# needed again
# require 'rgl/adjacency'
# require 'rgl/dijkstra'

# Tag class
class Tag < ApplicationRecord
  has_many :course_tag_joins
  has_many :courses, through: :course_tag_joins
  has_many :lecture_tag_disabled_joins
  has_many :disabled_lectures, through: :lecture_tag_disabled_joins,
                               source: :lecture
  has_many :lecture_tag_additional_joins
  has_many :additional_lectures, through: :lecture_tag_additional_joins,
                                 source: :lecture
  has_many :lesson_tag_joins
  has_many :lessons, through: :lesson_tag_joins
  has_many :section_tag_joins
  has_many :sections, through: :section_tag_joins
  has_many :medium_tag_joins
  has_many :media, through: :medium_tag_joins
  has_many :relations, dependent: :destroy
  has_many :related_tags, through: :relations, dependent: :destroy
  validates :title, presence: { message: 'Es muss ein Titel angegeben werden.'},
                    uniqueness: { message: 'Titel ist bereits vergeben.'}
  validate :additional_lectures_sane?
  validate :disabled_lectures_sane?

  def self.ids_titles_json
    Tag.order(:title).map { |t| { id: t.id, title: t.title } }.to_json
  end

  def self.similar_tags(search_string)
    jarowinkler = FuzzyStringMatch::JaroWinkler.create(:pure)
    Tag.where(id: Tag.all.select do |t|
                    jarowinkler.getDistance(t.title.downcase,
                                            search_string.downcase) > 0.9
                  end
                  .map(&:id))
  end

  def self.select_by_title
    Tag.all.to_a.sort_by { |t| t.title.downcase }.map { |t| [t.title, t.id] }
  end

  def tags_in_neighbourhood
    ids = related_tags.all.map { |t| t.related_tags.pluck(:id) }.flatten.uniq
    related_ids = related_tags.pluck(:id) + [id]
    Tag.where(id: ids - related_ids)
  end

  def in_lecture?(lecture)
    return false unless (lecture.course.tags.include?(self) &&
                        !lecture.disabled_tags.include?(self)) ||
                        lecture.additional_tags.include?(self)
    true
  end

  def in_lectures?(lectures)
    lectures.map { |l| in_lecture?(l) }.include?(true)
  end

  def lectures
    Lecture.where(id: Lecture.all.select { |l| in_lecture?(l) }.map(&:id))
  end

  private

  def additional_lectures_sane?
    if (additional_lectures.to_a & courses.collect{ |c| c.lectures }.flatten).empty?
      return true
    else
      errors.add(:additional_lectures, 'Eine der zusätzlichen Vorlesungen gehört zu einem ' \
                        'Modul, was zu diesem Tag aktiviert ist.')
      return false
    end
  end

  def disabled_lectures_sane?
    return true if disabled_lectures.empty?
    if (disabled_lectures.to_a & courses.collect{ |c| c.lectures }.flatten).present?
      return true
    else
      errors.add(:disabled_lectures, 'Eine der deaktivierten Vorlesungen gehört nicht zu einem ' \
                                     'Modul, was zu diesem Tag aktiviert ist.')
      return false
    end
  end
end
