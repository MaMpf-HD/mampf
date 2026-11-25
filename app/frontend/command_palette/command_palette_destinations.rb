# The staff pages of a lecture one can jump to from the command palette: the
# tabs of its edit page and the pages linked from there. The pages of its
# sidebar come from LecturePages.
module CommandPaletteDestinations
  Destination = Data.define(:key, :icon, :condition, :path) do
    def offered_for?(lecture)
      condition.call(lecture)
    end
  end

  ROUTES = Rails.application.routes.url_helpers
  ALWAYS = ->(_lecture) { true }

  def self.destination(key, icon, path)
    Destination.new(key: key, icon: icon, condition: ALWAYS, path: path)
  end

  def self.edit_tab(key, icon, tab)
    Destination.new(key: key, icon: icon,
                    condition: ->(lecture) { LectureEditTabs.for(lecture).include?(tab) },
                    path: ->(lecture) { ROUTES.edit_lecture_path(lecture, tab: tab) })
  end

  ALL = [
    edit_tab("edit_content", "bi-pencil-square", "content"),
    edit_tab("edit_home", "bi-house-gear", "home"),
    edit_tab("settings", "bi-gear", "settings"),
    edit_tab("people", "bi-person-badge", "people"),
    edit_tab("groups", "bi-diagram-3", "groups"),
    edit_tab("participants", "bi-person-lines-fill", "participants"),
    edit_tab("orga", "bi-calendar-event", "orga"),
    edit_tab("communication", "bi-envelope", "communication"),
    edit_tab("assessments", "bi-clipboard-data", "assessments"),
    edit_tab("exams", "bi-journal-check", "exams"),
    destination("campaigns", "bi-signpost-split",
                ->(lecture) { ROUTES.lecture_registration_campaigns_path(lecture) }),
    destination("performance", "bi-graph-up",
                ->(lecture) { ROUTES.lecture_student_performance_records_path(lecture) }),
    destination("certifications", "bi-patch-check",
                lambda { |lecture|
                  ROUTES.lecture_student_performance_certifications_path(lecture)
                })
  ].freeze
end
