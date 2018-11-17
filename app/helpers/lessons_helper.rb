module LessonsHelper
  def lesson_link(lesson, inspection)
    inspection ? inspect_lesson_path(lesson) : edit_lesson_path(lesson)
  end
end
