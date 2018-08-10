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

  def hide(value)
    value ? 'none;' : 'block;'
  end

  def show(value)
    value ? 'block;' : 'none;'
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

  def get_lecture_id
    return cookies[:current_lecture].to_i unless cookies[:current_lecture].nil?
    return 1 if current_user.nil?
    return current_user.lectures.first.id unless current_user.lectures.empty?
    1
  end

  def get_course_id
    return cookies[:current_course].to_i unless cookies[:current_course].nil?
    return 1 if current_user.nil?
    return current_user.courses.first.id unless current_user.courses.empty?
    1
  end

end
