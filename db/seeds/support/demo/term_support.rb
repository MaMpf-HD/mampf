module Demo
  # The demo data needs two terms: the one it plays in, where everything is
  # settled, and the one after it, where anything still being registered for
  # belongs.
  module TermSupport
    module_function

    def active_term
      Term.active || Term.order(:year, :season).last
    end

    def next_term
      term = active_term
      year, season = term.season == "SS" ? [term.year, "WS"] : [term.year + 1, "SS"]
      Term.find_or_create_by!(year: year, season: season)
    end

    def label(term)
      "#{term.season} #{term.year}"
    end

    def find_or_create_lecture!(term:, teacher:, course_title:, short_title:,
                                sort: "lecture")
      course = Course.find_or_create_by!(title: course_title) do |record|
        record.short_title = short_title
      end

      Lecture.find_by(course: course, term: term) ||
        FactoryBot.create(:lecture, :released_for_all,
                          course: course, term: term, teacher: teacher,
                          sort: sort, locale: "en")
    end
  end
end
