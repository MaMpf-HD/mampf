# Tags Helper
module TagsHelper
  def tags_except_self_for_selector(tag)
    Tag.where.not(id: tag.id).natural_sort_by(&:title)
       .map { |t| [t.title, t.id] }
  end

  def related_tag_ids_selection(tag)
    tag.related_tags.natural_sort_by(&:title).map(&:id)
  end
end
