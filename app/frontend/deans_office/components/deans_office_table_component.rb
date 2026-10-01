# Lists course counts, teaching teams and registration phases for the dean's
# office. Keeps courses without groups or registration in a collapsed list, so
# the table holds only what can be compared.
class DeansOfficeTableComponent < ViewComponent::Base
  def initialize(overview:, section:, courses:, by_phase:)
    super()
    @overview = overview
    @section = section
    listed, @unregistered = courses.partition { |course| overview.in_table?(course) }
    @courses = overview.ordered(listed, by_phase: by_phase)
    @by_phase = by_phase
  end

  def heading_id
    "deans-office-#{@section}"
  end

  def seminars?
    @section == :seminars
  end

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

  # Header ids for every cell, since a course's row and the phase heading
  # above it sit in separate row groups that scope alone cannot join.
  def column_id(key)
    "#{heading_id}-#{key}"
  end

  def phase_id(phase)
    "#{heading_id}-phase-#{phase}"
  end

  def title_id(course)
    dom_id(course, :deans_office_title)
  end

  def cell_headers(course, phase, key)
    [column_id(key), title_id(course), (phase_id(phase) if phase)].compact.join(" ")
  end

  def teacher_name(course)
    course.teacher && @overview.person_name(course.teacher)
  end

  def groups_or_talks(course)
    seminars? ? talks(course) : groups(course)
  end

  def state_lines(course)
    by_phase = @overview.groups_by_phase(course)
    return [t("deans_office.phases.#{@overview.phase(course)}")] if by_phase.size <= 1

    by_phase.map do |phase, groups|
      t("deans_office.phase_with_groups", phase: t("deans_office.phases.#{phase}"),
                                          groups: kinds(groups))
    end
  end

  # Omits the toggle for talks-only courses, because talks have no detail rows.
  def details?(course)
    course.tutorials.any? || course.cohorts.any?
  end

  private

    # Counts tutorials apart from flexible groups, because the dean's office
    # pays for tutorials.
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
