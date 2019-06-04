# Chapters Helper
module ChaptersHelper
  def chapter_positions_for_select(chapter)
    [[t('basics.at_the_beginning'), 0]] + chapter.lecture.select_chapters -
      [[chapter.to_label, chapter.position]]
  end
end