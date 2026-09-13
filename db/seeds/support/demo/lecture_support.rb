module Demo
  # Where the demo data plays: the lecture the shipped seed opens on.
  #
  # It used to be looked up by its primary key, which only ever held because
  # one particular dump happened to hand out that key. A database seeded from
  # scratch hands out others, so the lecture is identified by what it is --
  # the demo course in the term the demo plays in -- rather than by its id.
  module LectureSupport
    module_function

    COURSE_TITLE = "Lineare Algebra 2".freeze
    TEACHER_EMAIL = "teacher@mampf.edu".freeze
    MISSING_LECTURE_MESSAGE =
      "No demo lecture found (course \"#{COURSE_TITLE}\"). Run just seed first."
      .freeze
    MISSING_TEACHER_MESSAGE =
      "User #{TEACHER_EMAIL} not found. Run just seed first.".freeze

    # Falls back to the latest term the course ran in, so that a build which
    # has just moved the data forward still finds it.
    def find
      course = Course.find_by(title: COURSE_TITLE)
      return if course.nil?

      lectures = Lecture.where(course: course)
      lectures.find_by(term: Demo::TermSupport.active_term) || latest(lectures)
    end

    def find!
      find || raise(MISSING_LECTURE_MESSAGE)
    end

    def teacher
      User.find_by(email: TEACHER_EMAIL)
    end

    def teacher!
      teacher || raise(MISSING_TEACHER_MESSAGE)
    end

    # Terms are counted in half years, so that WS follows SS within a year.
    def latest(lectures)
      lectures.includes(:term).max_by do |lecture|
        term = lecture.term
        if term.nil?
          -1
        else
          (term.year * 2) + (term.season == "SS" ? 0 : 1)
        end
      end
    end
  end
end
