module MediaHelper

  def all_teachables
    Course.order(:title).map { |c| [c.short_title, 'Course-' + c.id.to_s] } +
      Lecture.sort_by_date(Lecture.all)
             .map { |l| [l.short_title, 'Lecture-' + l.id.to_s] } +
      Lesson.all.order(:date).reverse
            .map { |l| [l.short_title_with_lecture_date, 'Lesson-' + l.id.to_s ] }
  end
end
