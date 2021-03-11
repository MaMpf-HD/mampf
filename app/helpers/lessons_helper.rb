# Lessons Helper
module LessonsHelper
  # Returns the list of tags of this section, followed by all other tags
  # tags, all given by label, together with their ids.
  # Is used in options_for_select in form helpers.
  def lesson_tag_selection(lesson)
    lesson.section_tags.map { |t| t.extended_title_id_hash }
          .map { |t| [t[:title], t[:id]] }
  end

  # returns true if it is not an inspection AND the current user has
  # editing rights to the lecture (beig editor by inheritance or admin)
  def no_inspection_and_editor?(inspection, lecture)
    !inspection &&
      (current_user.admin || current_user.in?(lecture.editors_with_inheritance))
  end

  def edit_or_show_lesson_path(lesson)
    if current_user.admin ||
       lesson.lecture.editors_with_inheritance.include?(current_user)
      return edit_lesson_path(lesson)
    end
    lesson_path(lesson)
  end
end
