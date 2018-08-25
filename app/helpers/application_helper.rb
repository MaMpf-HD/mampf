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

  def show_tab(value)
    value ? 'show active' : ''
  end

  def media_types
    { 'kaviar' => ['Kaviar'], 'sesam' => ['Sesam'],
      'keks' => ['KeksQuiz', 'KeksQuestion'], 'kiwi' => ['Kiwi'],
      'erdbeere' => ['Erdbeere'], 'reste' => ['Reste'] }
  end

  def media_sorts
    ['kaviar', 'sesam', 'keks', 'kiwi', 'erdbeere', 'reste']
  end

  def media_names
    { 'kaviar' => 'KaViaR', 'sesam' => 'SeSAM',
      'keks' => 'KeKs', 'kiwi' => 'KIWi',
      'erdbeere' => 'ErDBeere', 'reste' => 'RestE' }
  end

  def lecture_media(media)
    media.select { |m| m.teachable_type.in?(['Lecture', 'Lesson']) }
  end

  def course_media(media)
    media.select { |m| m.teachable_type == 'Course' }
  end

  def lecture_course_teachables(media)
    lecture_ids =  lecture_media(media).map { |m| m.teachable.lecture }
                                .map(&:id).uniq
    course_ids = course_media(media).map { |m| m.teachable.course }
                                    .map(&:id).uniq
    lectures = Lecture.where(id: lecture_ids)
    courses = Course.where(id: course_ids)
    lectures + courses
  end

  def relevant_media(teachable, media)
    if teachable.class == Course
      return course_media(media).select { |m| m.course == teachable }
    end
    return lecture_media(media).select{ |m| m.teachable.lecture == teachable }
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
    return true if controller == 'tags' && action != 'show'
    false
  end
end
