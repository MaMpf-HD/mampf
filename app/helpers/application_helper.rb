# ApplicationHelper module
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

  def active(value)
    value ? 'active' : ''
  end

  def split_list(list, pieces = 4)
    group_size = (list.count / pieces) != 0 ? list.count / pieces : 1
    groups = list.in_groups_of(group_size)
    diff = groups.count - pieces
    return groups if diff <= 0
    tail = groups.pop(diff).first(diff).flatten
    groups.last.concat(tail)
    groups
  end

  def course_id_from_cookie
    return cookies[:current_course].to_i unless cookies[:current_course].nil?
    return if current_user.nil?
    return current_user.courses.first.id unless current_user.courses.empty?
  end

  def administrates?(controller, action)
    return true if controller == 'administration'
    return true if controller == 'terms'
    return true if controller =='courses' && action != 'show'
    return true if controller == 'users' && action != 'teacher'
    false
  end
end
