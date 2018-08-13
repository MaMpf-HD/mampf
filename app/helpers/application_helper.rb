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

  def get_course_id
    return cookies[:current_course].to_i unless cookies[:current_course].nil?
    return 1 if current_user.nil?
    return current_user.courses.first.id unless current_user.courses.empty?
    1
  end

end
