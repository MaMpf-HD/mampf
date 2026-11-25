# The tabs of a lecture's edit page (lectures/edit/edit), by the names that
# edit_lecture_path(lecture, tab:) takes.
module LectureEditTabs
  ALL = ["content", "home", "settings", "people", "groups", "participants",
         "orga", "communication", "assessments", "exams"].freeze

  # A legacy seminar manages its tutorials on the people tab and has no
  # groups and participants tabs.
  def self.for(lecture)
    return ALL unless lecture.legacy_seminar

    ALL - ["groups", "participants"]
  end
end
