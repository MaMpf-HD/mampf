# ApplicationHelper module
module ApplicationHelper
  # Returns the complete url for the media upload folder if in production
  def host
    Rails.env.production? ? ENV['MEDIA_SERVER'] + '/' + ENV['MEDIA_FOLDER'] : ''
  end

  # The HTML download attribute only works for files within the domain of
  # the webpage. Therefore, we use an apache redirect from an internal folder
  # which is stored in the DOWNLOAD_LOCATION environment variable, to
  # the actual media server.
  # This is used for the download buttons for videos and manuscripts.
  def download_host
    Rails.env.production? ? ENV['DOWNLOAD_LOCATION'] : ''
  end

  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = 'MaMpf'
    if page_title.empty?
      base_title
    else
      base_title + ' | ' + page_title
    end
  end

  # next methods are service methods for the display status of HTML elmements
  def hide(value)
    value ? 'none;' : 'block;'
  end

  def show(value)
    value ? 'block;' : 'none;'
  end

  def show_inline(value)
    value ? 'inline;' : 'none;'
  end

  def show_no_block(value)
    value ? '' : 'none;'
  end

  # active attribute for navs
  def active(value)
    value ? 'active' : ''
  end

  # show/collapse attributes for collapses and accordions
  def show_collapse(value)
    value ? 'show collapse' : 'collapse'
  end

  def show_tab(value)
    value ? 'show active' : ''
  end

  # media_sort -> database fields
  def media_types
    { 'kaviar' => ['Kaviar'], 'sesam' => ['Sesam'],
      'keks' => ['KeksQuiz', 'KeksQuestion'], 'kiwi' => ['Kiwi'],
      'erdbeere' => ['Erdbeere'], 'reste' => ['Reste'] }
  end

  # media_sorts
  def media_sorts
    ['kaviar', 'sesam', 'keks', 'kiwi', 'erdbeere', 'reste']
  end

  # media_sort -> acronym
  def media_names
    { 'kaviar' => 'KaViaR', 'sesam' => 'SeSAM',
      'keks' => 'KeKs', 'kiwi' => 'KIWi',
      'erdbeere' => 'ErDBeere', 'reste' => 'RestE' }
  end

  # Selects all media associated to lectures and lessons from a given list
  # of media
  def lecture_media(media)
    media.select { |m| m.teachable_type.in?(['Lecture', 'Lesson']) }
  end

  # Selects all media associated to courses from a given list of media
  def course_media(media)
    media.select { |m| m.teachable_type == 'Course' }
  end

  # For a given list of media, returns the array of courses and lectures
  # the given media are associated to.
  def lecture_course_teachables(media)
    lecture_ids =  lecture_media(media).map { |m| m.teachable.lecture }
                                       .map(&:id).uniq
    course_ids = course_media(media).map { |m| m.teachable.course }
                                    .map(&:id).uniq
    lectures = Lecture.where(id: lecture_ids)
    courses = Course.where(id: course_ids)
    courses + lectures
  end

  # For a given list of media and a given (a)course/(b)lecture,
  # returns all media who are
  # (a) associated to the same given course
  # (b) associated to the given lecture or a lesson associated to the given
  # lecture
  def relevant_media(teachable, media)
    if teachable.class == Course
      return course_media(media).select { |m| m.course == teachable }
    end
    lecture_media(media).select { |m| m.teachable.lecture == teachable }
  end

  # splits an array into smaller parts
  def split_list(list, pieces = 4)
    group_size = (list.count / pieces) != 0 ? list.count / pieces : 1
    groups = list.in_groups_of(group_size)
    diff = groups.count - pieces
    return groups if diff <= 0
    tail = groups.pop(diff).first(diff).flatten
    groups.last.concat(tail)
    groups
  end

  # Determines current course id form cookie.
  # Is used for the rendering of the sidebar.
  def course_id_from_cookie
    return cookies[:current_course].to_i unless cookies[:current_course].nil?
    return if current_user.nil?
    return current_user.courses.first.id unless current_user.courses.empty?
  end

  # returns true for 'media#enrich' action
  def enrich?(controller, action)
    return true if controller == 'media' && action == 'enrich'
    false
  end

  # Returns the path for the inspect action for a given course/lecture/lesson.
  def inspect_teachable_path(teachable)
    return inspect_course_path(teachable) if teachable.class == Course
    return inspect_lecture_path(teachable) if teachable.class == Lecture
    inspect_lesson_path(teachable)
  end

  # cuts off a given string so that a given number of letters is not exceeded
  # string is given ... as ending if it is too long
  def shorten(title, max_letters)
    return '' unless title.present?
    return title unless title.length > max_letters
    title[0, max_letters - 3] + '...'
  end

  # Returns the grouped list of all courses/lectures/references together
  # with their ids. Is used in grouped_options_for_select in form helpers.
  def grouped_teachable_list
    list = []
    Course.all.each do |c|
      lectures = [[c.short_title + ' alle', 'Course-' + c.id.to_s]]
      c.lectures.includes(:term).each do |l|
        lectures.push [l.short_title, 'Lecture-' + l.id.to_s]
      end
      list.push [c.title, lectures]
    end
    list.push ['externe Referenzen', [['extern alle', 'external-0']]]
  end

  # Returns the grouped list of all courses/lectures together with their ids.
  # Is used in grouped_options_for_select in form helpers
  def grouped_teachable_list_alternative
    list = []
    Course.all.each do |c|
      lectures = [[c.short_title + ' Modul', 'course-' + c.id.to_s]]
      c.lectures.includes(:term).each do |l|
        lectures.push [l.short_title, 'lecture-' + l.id.to_s]
      end
      list.push [c.title, lectures]
    end
    list
  end

  # Returns the path for the inspect or edit action of a given course,
  # depending on  whether the current user has editor rights for the course.
  def edit_or_inspect_course_path(course)
    if current_user.admin || course.editors.include?(current_user)
      return edit_course_path(course)
    end
    inspect_course_path(course)
  end

  # Returns the fontawesome icon name for inspecting or editing a given course,
  # depending on  whether the current user has editor rights for the course.
  def edit_or_inspect_course_icon(course)
    if current_user.admin || course.editors.include?(current_user)
      return 'far fa-edit'
    end
    'far fa-eye'
  end

  # Returns the path for the inspect or edit action of a given lecture,
  # depending on  whether the current user has editor rights for the course.
  # Editor rights are determnined by inheritance, e.g. module editors
  # can edit all lectures associated to the course.
  def edit_or_inspect_lecture_path(lecture)
    if current_user.admin ||
       lecture.editors_with_inheritance.include?(current_user)
      return edit_lecture_path(lecture)
    end
    inspect_lecture_path(lecture)
  end

  # Returns the fontawesome icon name for inspecting or editing a given lecture,
  # depending on  whether the current user has editor rights for the course.
  # Editor rights are determnined by inheritance, e.g. module editors
  # can edit all lectures associated to the course.
  def edit_or_inspect_lecture_icon(lecture)
    if current_user.admin ||
       lecture.editors_with_inheritance.include?(current_user)
      return 'far fa-edit'
    end
    'far fa-eye'
  end
end
