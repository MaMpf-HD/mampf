# ApplicationHelper module
module ApplicationHelper

  #returns the path that is associated to the MaMpf brand in the navbar
  def home_path
    return start_path if user_signed_in?
    root_path(params: { locale: I18n.locale})
  end

  # get current lecture from session object
  def current_lecture
    Lecture.find_by_id(cookies[:current_lecture_id])
  end

  # Returns the complete url for the media upload folder if in production
  def host
    Rails.env.production? ? ENV['MEDIA_SERVER'] + '/' + ENV['INSTANCE_NAME'] : ''
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
    return page_title if action_name == 'play' && controller_name == 'media'
    return 'Quiz' if action_name == 'take' && controller_name == 'quizzes'
    base_title = 'MaMpf'
    if user_signed_in? && current_user.notifications.any?
      base_title += " (#{current_user.notifications.size})"
    end
    base_title
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

  def text_dark(value)
    value ? '' : 'text-dark'
  end

  def text_dark_link(value)
    value ? 'text-primary' : 'text-dark'
  end

  # media_sort -> database fields
  def media_types
    { 'kaviar' => ['Kaviar'], 'sesam' => ['Sesam'],
      'keks' => ['Quiz'],
      'kiwi' => ['Kiwi'],
      'erdbeere' => ['Erdbeere'], 'nuesse' => ['Nuesse'],
      'script' => ['Script'], 'questions' => ['Question'],
      'remarks' => ['Remark'], 'reste' => ['Reste'] }
  end

  # media_sorts
  def media_sorts
    ['kaviar', 'sesam', 'keks', 'kiwi', 'erdbeere', 'nuesse', 'script',
     'questions', 'remarks', 'reste']
  end

  # media_sort -> acronym
  def media_names
    { 'kaviar' => t('categories.kaviar.plural'),
      'sesam' => t('categories.sesam.plural'),
      'keks' => t('categories.quiz.plural'),
      'kiwi' => t('categories.kiwi.singular'),
      'erdbeere' => t('categories.erdbeere.singular'),
      'nuesse' => t('categories.exercises.plural'),
      'script' => t('categories.script.singular'),
      'questions' => t('categories.question.plural'),
      'remarks' => t('categories.remark.plural'),
      'reste' => t('categories.reste.singular') }
  end

  # Selects all media associated to lectures and lessons from a given list
  # of media
  def lecture_media(media)
    media.where(teachable_type: ['Lecture', 'Lesson'] )
  end

  # Selects all media associated to courses from a given list of media
  def course_media(media)
    media.where(teachable_type: 'Course')
  end

  # For a given list of media, returns the array of courses and lectures
  # the given media are associated to.
  def lecture_course_teachables(media)
    teachables = media.pluck(:teachable_type, :teachable_id).uniq
    course_ids = teachables.select { |t| t.first == 'Course'}.map(&:second)
    lecture_ids = teachables.select { |t| t.first == 'Lecture'}.map(&:second)
    lesson_ids = teachables.select { |t| t.first == 'Lesson'}.map(&:second)
    lecture_ids += Lesson.where(id: lesson_ids).pluck(:lecture_id).uniq
    Course.where(id: course_ids) + Lecture.where(id: lecture_ids.uniq)
  end

  # For a given list of media and a given (a)course/(b)lecture,
  # returns all media who are
  # (a) associated to the same given course
  # (b) associated to the given lecture or a lesson associated to the given
  # lecture
  def relevant_media(teachable, media, limit)
    result = []
    if teachable.class == Course
      return media.where(teachable: teachable).order(:created_at)
                                              .reverse_order
                                              .first(limit)
    end
    media_ids = (teachable.media_with_inheritance.pluck(:id) & media.pluck(:id))
    Medium.where(id: media_ids).order(:created_at).reverse_order.first(limit)
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

  # returns true for 'media#enrich' action
  def enrich?(controller, action)
    return true if controller == 'media' && action == 'enrich'
    false
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
      lectures = [[c.short_title + ' (' + t('basics.all') + ')', 'Course-' + c.id.to_s]]
      c.lectures.includes(:term).each do |l|
        lectures.push [l.short_title_release, 'Lecture-' + l.id.to_s]
      end
      list.push [c.title, lectures]
    end
    list.push [t('admin.referral.external_references'),
               [[t('admin.referral.external_all'), 'external-0']]]
  end

  # Returns the grouped list of all courses/lectures together with their ids.
  # Is used in grouped_options_for_select in form helpers
  def grouped_teachable_list_alternative
    list = []
    Course.all.each do |c|
      lectures = [[c.short_title + ' Modul', 'Course-' + c.id.to_s]]
      c.lectures.includes(:term).each do |l|
        lectures.push [l.short_title, 'Lecture-' + l.id.to_s]
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

  # Returns the path for the inspect or edit action of a given medium,
  # depending on  whether the current user has editor rights for the course.
  # Editor rights are determined by inheritance
  def edit_or_inspect_medium_path(medium)
    if current_user.admin ||
       medium.editors_with_inheritance.include?(current_user)
      return edit_medium_path(medium)
    end
    inspect_medium_path(medium)
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

  # returns the given date in a more human readable form
  # anything older than today or yesterday gets reduced to the day.month.year
  # yesterday's/today's dates are return as 'gestern/heute' plus hour:mins
  def human_readable_date(date)
    return t('today')+ ', ' + date.strftime('%H:%M') if date.to_date == Date.today
    if date.to_date == Date.yesterday
      return t('yesterday') + ', ' + date.strftime('%H:%M')
    end
    I18n.localize date, format: :concise
  end

  # prepend a select prompt to selection for options_for_select
  def add_prompt(selection)
    [[t('basics.select'), '']] + selection
  end

  def quizzable_color(type)
    'bg-' + type.downcase
  end

  def questioncolor(value)
    value ? 'bg-question' : ''
  end

  def vertex_label(quiz, vertex_id)
    vertex_id.to_s + ' ' + quiz.quizzable(vertex_id)&.label.to_s
  end

  def ballot_box(correctness)
    raw(correctness ? '&#x2612;' : '&#x2610;')
  end

  def boxcolor(correctness)
    correctness ? 'correct' : 'incorrect'
  end

  def bgcolor(correctness)
    correctness ? 'bg-correct' : 'bg-incorrect'
  end

  def hide_as_class(value)
    value ? 'no_display' : ''
  end

  def helpdesk(text, html)
    tag.i class: 'far fa-question-circle helpdesk ml-2',
                  tabindex: -1,
                  data: { toggle: 'popover',
                          trigger: 'focus',
                          content: text,
                          html: html },
                  title: t('info')
  end

  def realization_path(realization)
    "/#{realization.first.downcase.pluralize}/#{realization.second}"
  end

  def first_course_independent?
    current_user.administrated_courses
                .natural_sort_by(&:title)
               &.first&.term_independent
  end
end
