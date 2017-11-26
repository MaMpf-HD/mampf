module ApplicationHelper
  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = 'MaMpf'
    if page_title.empty?
      base_title
    else
      base_title + ' | ' + page_title
    end
  end

  def split_list(list, n = 4)
    group_size = (list.count / n) != 0 ? list.count / n : 1
    groups = list.in_groups_of(group_size)
    diff = groups.count - n
    return groups if diff <= 0
    tail = groups.pop(diff).first(diff).flatten
    groups.last.concat(tail)
    return groups
  end

  def filter_tags_by_lectures(tags, filter_lectures)
    Tag.where(id: tags.select { |t| t.in_lectures?(filter_lectures) }.map(&:id))
  end

  def filter_lectures_by_lectures(lectures, filter_lectures)
    Lecture.where(id: lectures.pluck(:id) & filter_lectures.pluck(:id))
  end

  def filter_media_by_lectures(media, filter_lectures)
    Medium
      .where(id: media.select { |m| m.related_to_lectures?(filter_lectures) }
      .map(&:id))
  end
end
