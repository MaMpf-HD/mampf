module LecturesHelper
  def course_title(lecture)
    Course.find(lecture.course_id).title
  end
  def term_description(lecture)
    Term.find(lecture.term_id).season + ' ' + Term.find(lecture.term_id).year.to_s
  end
  def teacher(lecture)
    Teacher.find(lecture.teacher_id).name
  end
end
