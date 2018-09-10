module MediaHelper

  def all_teachables_selection(user)
    if user.admin?
      return Course.order(:title).map { |c| [c.short_title, 'Course-' + c.id.to_s] } +
        Lecture.sort_by_date(Lecture.all)
               .map { |l| [l.short_title, 'Lecture-' + l.id.to_s] } +
        Lesson.order(:date).reverse
              .map { |l| [l.short_title_with_lecture_date, 'Lesson-' + l.id.to_s ] }
    end
    Course.order(:title).select { |c| c.edited_by?(user) }
          .map { |c| [c.short_title, 'Course-' + c.id.to_s] } +
      Lecture.sort_by_date(Lecture.all)
             .select { |l| l.edited_by?(user) }
             .map { |l| [l.short_title, 'Lecture-' + l.id.to_s] } +
      Lesson.order(:date).reverse.select { |l| l.edited_by?(user) }
            .map { |l| [l.short_title_with_lecture_date, 'Lesson-' + l.id.to_s ] }
  end

  def sections_for_thyme(medium)
    medium.teachable.lecture.section_selection
  end

  def items_for_thyme(medium)
    if medium.teachable_type.in?(['Lesson', 'Lecture'])
      local_items = medium.teachable.lecture.items - medium.items
      local_selection = local_items.map { |i| [i.local_reference, i.id] }
    else
      local_items = medium.teachable.items - medium.items
      local_selection = local_items.map { |i| [i.global_reference, i.id] }
    end
    external_items = (Item.all - local_items).select(&:link?) - medium.items
    global_items = ((Item.all - local_items) - external_items) - medium.items
    external_selection = external_items.map { |i| [i.global_reference, i.id] }
    global_selection = global_items.map { |i| [i.global_reference, i.id] }
    local_selection + external_selection + global_selection
  end
end
