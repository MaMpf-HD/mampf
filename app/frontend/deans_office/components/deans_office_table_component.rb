# Lists a term's lectures or seminars for the dean's office: per course how
# many students, its tutorials or talks with their places, and how far its
# registration has got, with the groups behind a button. Courses without any
# registration are listed by name below the table.
class DeansOfficeTableComponent < ViewComponent::Base
  def initialize(overview:, section:, courses:, by_phase:)
    super()
    @overview = overview
    @section = section
    registered, @unregistered = courses.partition { |course| overview.registered?(course) }
    @courses = overview.ordered(registered, by_phase: by_phase)
    @by_phase = by_phase
  end

  def heading_id
    "deans-office-#{@section}"
  end

  def seminars?
    @section == :seminars
  end

  # One group per phase when ordered by phase; otherwise a single one
  # without a heading.
  def phase_groups
    return [[nil, @courses]] unless @by_phase

    @courses.chunk_while { |a, b| @overview.phase(a) == @overview.phase(b) }
            .map { |list| [@overview.phase(list.first), list] }
  end

  def filter_text(course)
    people = @overview.teachers(course).flat_map do |user|
      [@overview.person_name(user), user.name, user.email]
    end
    [course.course.title, course.sort_localized, *people].join(" ").downcase
  end

  def groups_or_talks(course)
    seminars? ? talks(course) : groups(course)
  end

  # The phase of the course's registration; where its groups differ, one
  # line per phase naming the groups in it.
  def state_lines(course)
    by_phase = @overview.groups_by_phase(course)
    return [t("deans_office.phases.#{@overview.phase(course)}")] if by_phase.size <= 1

    by_phase.map do |phase, groups|
      t("deans_office.phase_with_groups", phase: t("deans_office.phases.#{phase}"),
                                          groups: kinds(groups))
    end
  end

  # Whether opening the course shows anything: its tutorials or further
  # groups. Talks are only counted.
  def details?(course)
    course.tutorials.any? || course.cohorts.any?
  end

  private

    # Tutorials and further groups counted apart: only tutorials are what
    # the dean's office pays for.
    def groups(lecture)
      kinds(lecture.tutorials + lecture.cohorts).presence || t("deans_office.groups.none")
    end

    def kinds(groups)
      counts = groups.group_by(&:class).transform_values(&:size)
      { Tutorial => "groups.tutorials", Talk => "talks.count", Cohort => "groups.flexible" }
        .filter_map { |kind, key| t("deans_office.#{key}", count: counts[kind]) if counts[kind] }
        .join(", ")
    end

    def talks(seminar)
      count = seminar.talks.size
      return t("deans_office.talks.none") if count.zero?

      assigned = @overview.talks_assigned(seminar)
      key = { count => "all", 0 => "none" }.fetch(assigned, "some")
      t("deans_office.talks.summary", talks: t("deans_office.talks.count", count: count),
                                      assigned: t("deans_office.talks.assigned.#{key}",
                                                  count: assigned))
    end
end
