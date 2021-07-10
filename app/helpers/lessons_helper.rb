# Lessons Helper
module LessonsHelper
  # Returns the list of tags of this section, followed by all other tags
  # tags, all given by label, together with their ids.
  # Is used in options_for_select in form helpers.
  def lesson_tag_selection(lesson)
    lesson.section_tags.map { |t| t.extended_title_id_hash }
          .map { |t| [t[:title], t[:id]] }
  end

  def edit_or_show_lesson_path(lesson)
    return edit_lesson_path(lesson) if current_user.can_edit?(lesson.lecture)
    lesson_path(lesson)
  end
end
