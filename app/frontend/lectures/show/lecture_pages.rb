# Pages of a lecture's sidebar (the command palette reuses this).
module LecturePages
  Page = Data.define(:key, :icon, :label_key, :section, :audience, :project,
                     :needs_access, :new_tab, :active_prefix, :shown, :path) do
    def active_on?(request, path)
      return true if project && request.params["project"] == project
      return true if active_prefix && request.path.start_with?(active_prefix)

      request.path == path
    end

    def enabled?(lecture, user, content_accessible)
      return false unless path.call(lecture)
      return true unless needs_access
      return false unless content_accessible

      project.nil? || lecture.page_available?(project, user)
    end
  end

  ROUTES = Rails.application.routes.url_helpers
  DEFAULTS = { audience: :member, project: nil, needs_access: true, new_tab: false,
               active_prefix: nil, shown: ->(_lecture) { true } }.freeze

  def self.page(key, icon, label_key, **options)
    Page.new(key: key, icon: icon, label_key: label_key, **DEFAULTS.merge(options))
  end

  ALL = [
    page("home", "bi-house", "basics.home",
         section: :materials, project: "home", needs_access: false,
         path: ->(lecture) { ROUTES.lecture_home_path(lecture) }),
    page("outline", "bi-book", "basics.outline",
         section: :materials,
         path: ->(lecture) { ROUTES.lecture_outline_path(lecture) }),
    page("lesson_materials", "bi-collection-play", "categories.lesson_material.plural",
         section: :materials, project: "lesson_material",
         path: ->(lecture) { ROUTES.lecture_lesson_materials_path(lecture) }),
    page("script", "bi-file-earmark", "categories.script.singular",
         section: :materials, project: "script",
         path: ->(lecture) { ROUTES.lecture_script_path(lecture) }),

    page("exercises", "bi-pencil", "categories.exercise.plural",
         section: :exercises, project: "exercise",
         path: ->(lecture) { ROUTES.lecture_exercises_path(lecture) }),
    page("submissions", "bi-people", "categories.submissions",
         section: :exercises, audience: :student,
         path: ->(lecture) { ROUTES.lecture_submissions_path(lecture) }),
    page("tutorials", "bi-people", "categories.tutorials",
         section: :exercises, audience: :tutor,
         path: ->(lecture) { ROUTES.lecture_tutorials_path(lecture) }),
    page("cohorts", "bi-people", "categories.cohorts",
         section: :exercises, audience: :cohort_tutor, needs_access: false,
         path: ->(lecture) { ROUTES.lecture_cohort_participants_path(lecture) }),

    page("quizzes", "bi-question-square", "categories.quiz.plural",
         section: :practice, project: "quiz",
         path: ->(lecture) { ROUTES.lecture_quizzes_path(lecture) }),
    # Vignettes are not shown (not even grayed out) if a lecture doesn't use them.
    page("vignettes", "bi-clipboard-check", "vignettes.vignettes",
         section: :practice, active_prefix: "/questionnaires/",
         shown: ->(lecture) { lecture.vignettes? },
         path: ->(lecture) { ROUTES.lecture_questionnaires_path(lecture) }),
    page("self_test", "bi-star", "categories.test.singular",
         section: :practice, project: "self_test",
         path: ->(lecture) { ROUTES.show_random_quizzes_path(lecture) }),
    page("worked_examples", "bi-mortarboard", "categories.worked_example.plural",
         section: :practice, project: "worked_example",
         path: ->(lecture) { ROUTES.lecture_worked_examples_path(lecture) }),
    page("repetitions", "bi-layers", "categories.repetition.singular",
         section: :practice, project: "repetition",
         path: ->(lecture) { ROUTES.lecture_repetitions_path(lecture) }),
    page("miscellaneous", "bi-circle", "categories.miscellaneous.singular",
         section: :practice, project: "miscellaneous",
         path: ->(lecture) { ROUTES.lecture_miscellaneous_path(lecture) }),

    page("forum", "bi-chat", "categories.board",
         section: :exchange, new_tab: true,
         path: ->(lecture) { lecture.forum_path }),
    page("announcements", "bi-megaphone", "categories.announcements",
         section: :exchange, project: "announcements",
         path: ->(lecture) { ROUTES.lecture_announcements_path(lecture) }),
    page("organizational", "bi-info-square", "categories.organizational_html",
         section: :exchange, project: "organizational",
         path: ->(lecture) { ROUTES.lecture_organizational_path(lecture) }),
    page("course", "bi-hexagon", "categories.course",
         section: :exchange,
         path: ->(lecture) { ROUTES.lecture_course_path(lecture) })
  ].freeze

  def self.visible(lecture, user, tutor: lecture.tutor?(user),
                   cohort_tutor: lecture.cohort_tutor?(user))
    audiences = [:member]
    audiences << :tutor if tutor
    audiences << :student if !tutor && !user.editor_or_teacher_in?(lecture)
    audiences << :cohort_tutor if cohort_tutor
    ALL.select { |page| audiences.include?(page.audience) && page.shown.call(lecture) }
  end
end
