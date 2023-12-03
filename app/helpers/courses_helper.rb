# Courses Helper
module CoursesHelper
  # create text for notification about new course in notification dropdown menu
  def course_notification_item_header(course)
    t('notifications.new_course', title: course.title)
  end

  # create text for notification card
  def course_notification_item_details(course)
    t('notifications.subscribe_course')
  end

  # create text for notification about new course in notification card
  def course_notification_card_text(course)
    t('notifications.new_course_created_html', title: course.title)
  end

  # create link for notification about new lecture in notification card
  def course_notification_card_link
    t('notifications.subscribe_course_html',
      profile: link_to(t('notifications.profile'),
                       edit_profile_path,
                       class: 'darkblue'))
  end

  def course_link_or_text(course, user)
    unless user.admin || user.in?(course.editors)
      return course.title
    end

    link_to(course.title, edit_course_path(course))
  end

  def course_edit_icon(course)
    link_to edit_course_path(course),
            class: 'text-dark me-2',
            style: 'text-decoration: none;',
            data: { toggle: 'tooltip',
                    placement: 'bottom' },
            title: t('buttons.edit') do
      tag.i class: 'far fa-edit'
    end
  end
end
