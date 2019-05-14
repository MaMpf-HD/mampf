# Lessons Helper
module LessonsHelper
  # returns the path for the edit or inspect action for the lesson
  def lesson_link(lesson, inspection)
    inspection ? inspect_lesson_path(lesson) : edit_lesson_path(lesson)
  end

  # Returns the list of tags of this section, followed by all other tags
  # tags, all given by label, together with their ids.
  # Is used in options_for_select in form helpers.
  def lesson_tag_selection(lesson)
    lesson.section_tags.map { |t| t.extended_title_id_hash }
          .map { |t| [t[:title], t[:id]] } +
      lesson.complement_of_section_tags
            .map { |t| t.extended_title_id_hash }
            .natural_sort_by{ |t| t[:title] }
            .map { |t| [t[:title], t[:id]] }
  end

  # returns true if it is not an inspection AND the current user has
  # editing rights to the lecture (beig editor by inheritance or admin)
  def no_inspection_and_editor?(inspection, lecture)
    !inspection &&
      (current_user.admin || current_user.in?(lecture.editors_with_inheritance))
  end
end
