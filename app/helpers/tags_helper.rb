# Tags Helper
module TagsHelper
  def related_tag_ids_selection(tag)
    tag.related_tags.natural_sort_by(&:title).map(&:id)
  end
end
