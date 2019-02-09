# Sections Helper
module SectionsHelper
  # the next methods return arrays of sections/chapter label together with
  # the corresponding ids for the use in options_for_select
  def lecture_chapters_for_select(section)
    section.chapter.lecture.chapters.includes(:lecture)
           .map { |c| [c.to_label, c.id] }
  end

  def section_positions_for_select(section)
    [['am Anfang', 0]] + section.chapter.select_sections -
      [[section.to_label, section.position]]
  end

  def new_section_position_for_select(chapter)
    [['am Anfang des Kapitels', 0]] + chapter.select_sections
  end

  def section_lessons_for_select(section)
    Lesson.where(lecture: section.lecture).includes(:lecture).order(:date)
          .map { |l| [l.to_label, l.id] }
  end
end
