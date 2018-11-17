module MediaHelper

  def all_teachables_selection(user)
    if user.admin?
      return Course.order(:title).map { |c| [c.short_title, 'Course-' + c.id.to_s] } +
        Lecture.sort_by_date(Lecture.includes(:course).all)
               .map { |l| [l.short_title, 'Lecture-' + l.id.to_s] } +
        Lesson.includes(:lecture).order(:date).reverse
              .map { |l| [l.short_title_with_lecture_date, 'Lesson-' + l.id.to_s ] }
    end
    Course.includes(:editors, :editable_user_joins)
          .order(:title).select { |c| c.edited_by?(user) }
          .map { |c| [c.short_title, 'Course-' + c.id.to_s] } +
      Lecture.sort_by_date(Lecture.includes(:course, :editors).all)
             .select { |l| l.edited_by?(user) }
             .map { |l| [l.short_title, 'Lecture-' + l.id.to_s] } +
      Lesson.includes(:lecture).order(:date).reverse.select { |l| l.edited_by?(user) }
            .map { |l| [l.short_title_with_lecture_date, 'Lesson-' + l.id.to_s ] }
  end

  def sections_for_thyme(medium)
    medium.teachable.lecture.section_selection
  end

  def inspect_or_edit_medium_path(medium, inspection)
    inspection ? inspect_medium_path(medium) : edit_medium_path(medium)
  end
end
