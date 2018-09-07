module MediaHelper

  def all_teachables
    Course.order(:title).map { |c| [c.short_title, 'course-' + c.id.to_s] } +
      Lecture.sort_by_date(Lecture.all)
             .map { |l| [l.short_title, 'lecture-' + l.id.to_s] } +
      Lesson.all.order(:date).reverse
            .map { |l| [l.short_title_with_lecture_date, 'lesson-' + l.id.to_s ] }
  end
end
