# Lectures Helper
module LecturesHelper
  # returns true if it is an inspection AND the current user has editing rights
  # to the lecture (beig editor by inheritance or admin)
  def inspection_and_editor?(inspection, lecture)
    inspection &&
      (current_user.admin || current_user.in?(lecture.editors_with_inheritance))
  end

  # returns for a given lecture and inspection status
  # - the path for the inspect action for the lecture's course if
  #    (1) the user is no admin
  #    AND
  #    (2) it is an inspection and the user is no editor of the course
  # - the path for the edit action for the lecture's course in all other cases
  def inspect_or_edit_course_from_lecture(inspection, lecture)
    if (inspection || !lecture.course.editors.include?(current_user)) &&
       !current_user.admin?
      return inspect_course_path(lecture.course)
    end
    edit_course_path(lecture.course)
  end

  # is the current user allowed to delete the given lecture and is it
  # irrelevant enough to be able to do so?
  def lecture_deletable?(lecture, inspection)
    !inspection && lecture.lessons.empty? && lecture.media.empty? &&
      (current_user.admin? ||
        lecture.editors_with_inheritance.include?(current_user))
  end
end
