# The pointing table of a sheet: a row for every hand-in and one for everybody
# else on the roster. A tutor sees their group, the lecturer every group.
class TutorialPointingTableComponent < ViewComponent::Base
  # A row is a hand-in or somebody on the roster without one.
  Row = Struct.new(:submission, :user, :tutorial, keyword_init: true)

  attr_reader :sort, :dir

  def initialize(assignment:, grading_scope: nil, sort: nil, dir: nil)
    super()
    @assignment = assignment
    @lecture = assignment.lecture
    @grading_scope = grading_scope
    @sort = sort if sort == "total"
    @dir = dir == "asc" ? "asc" : "desc"
    if grading_scope.is_a?(Tutorial)
      @tutorial = @grading_scope
      init_tutor_case
    elsif grading_scope.is_a?(Lecture)
      init_teacher_case
    end
  end

  def init_tutor_case
    @mode = "tutor"
    @stack = @assignment.submissions.where(tutorial: @tutorial).proper
                        .order(:last_modification_by_users_at)
                        .includes(:users, tutorial: :tutors)
    @non_submitters = @assignment.non_submitters_in_tutorial(@tutorial)
    @participations_by_user_id =
      preload_participations(@non_submitters, @stack, groups_of(@non_submitters))
  end

  def init_teacher_case
    @mode = "teacher"
    @tutorials = @lecture.tutorials
    @stack = @assignment.submissions.proper
                        .order(:last_modification_by_users_at)
                        .includes(:users, tutorial: :tutors)
    @submissions_by_tutorial = @stack.group_by(&:tutorial)

    @non_submitters = @assignment.non_submitters_in_tutorials
    # Somebody who left the groups after handing in sits with the group that
    # has the sheet - as a file row or a roster row - not among those in none.
    @non_tutorial_participants = @assignment.applicable_users_not_in_tutorials
                                            .where.not(id: @non_submitters.map(&:id) +
                                                           @stack.flat_map(&:user_ids))
    listed = @non_submitters.to_a + @non_tutorial_participants.to_a
    @participations_by_user_id = preload_participations(listed, @stack, groups_of(listed))

    # Somebody who moved groups after handing in on paper stays with the group
    # that has the sheet; everybody else sits with the group they are in.
    @non_submitters_by_tutorial = @non_submitters.group_by do |user|
      @participations_by_user_id[user.id]&.tutorial || membership_tutorials[user.id]
    end
  end

  # Batch creation avoids per-student inserts and validation queries.
  def preload_participations(non_submitters, submissions, groups)
    return {} unless @assignment.assessment

    seed_test_rows(non_submitters, groups) if @assignment.kind_test?
    user_ids = non_submitters.map(&:id) + submissions.flat_map(&:user_ids)
    rows = Assessment::Participation
           .where(user_id: user_ids, assessment: @assignment.assessment)
           .includes(:user, :task_points, :tutorial, :assessment)
           .index_by(&:user_id)
    rehome_blank_rows(rows, groups)
    rows
  end

  # The group each listed user is a member of now, nil for none: after the
  # deadline a group's page also lists people who have moved away and left a
  # row behind, so the page's own group is not the answer.
  def groups_of(users)
    users.to_h { |user| [user.id, membership_tutorials[user.id]] }
  end

  # Blank participations must follow tutorial membership so the current tutor
  # can enter points; recorded work must stay with its original tutorial.
  # Points may land on the row between this page's read and its write, so
  # the row is read again under the lock the point entry takes.
  def rehome_blank_rows(rows, groups)
    rows.each_value do |row|
      next unless groups.key?(row.user_id) && blank?(row)
      next if row.tutorial_id == groups[row.user_id]&.id

      row.with_lock { row.update!(tutorial: groups[row.user_id]) if blank?(row) }
    end
  end

  # Points taken back again leave task points of nil behind; those carry
  # nothing either.
  def blank?(row)
    row.pending? && row.submitted_at.nil? && !row.results_visible?
  end

  def seed_test_rows(users, groups)
    @assignment.assessment.seed_participations_from!(
      user_ids: users.map(&:id),
      tutorial_mapping: users.to_h { |user| [user.id, groups[user.id]&.id] },
      recompute: false
    )
  end

  def team_participations(submission)
    submission.users.map { |user| @participations_by_user_id[user.id] }
  end

  # Before the backfill worker has been round there is no participation yet;
  # the row is drawn from an unsaved one, and recording the hand-in saves it.
  # A test's rows are seeded before any is asked for, so this never builds
  # one for a test.
  def participation_for(user, tutorial)
    @participations_by_user_id[user.id] ||=
      Assessment::Participation.new(assessment: @assignment.assessment, user: user,
                                    tutorial: tutorial)
  end

  def grading_enabled?
    @assignment.assessable?
  end

  # The rows in the order the page shows them: a group's hand-ins, then its
  # roster; on the lecture's page group after group, those in no group last.
  # Sorted by the total, the groups run together - the tutorial column tells
  # them apart - and rows without a total come last either way.
  def rows
    @rows ||= sort ? entries.sort_by { |row| sort_key(row) } : entries
  end

  def sorted?
    sort.present?
  end

  # The heading's link: the other direction while sorted, descending first.
  def sort_url
    next_dir = sorted? && dir == "desc" ? "asc" : "desc"
    if @grading_scope.is_a?(Tutorial)
      helpers.lecture_tutorials_path(@lecture, assignment: @assignment.id, tutorial: @tutorial.id,
                                               sort: "total", dir: next_dir)
    else
      helpers.assessment_assessment_path(@assignment.assessment, assessable_type: "Assignment",
                                                                 assessable_id: @assignment.id,
                                                                 tab: "points",
                                                                 sort: "total", dir: next_dir)
    end
  end

  def layout
    @layout ||= PointingTableLayout.for(assessable: @assignment, grading_scope: @grading_scope)
  end

  def toolbar
    PointingToolbarComponent.new(assignment: @assignment, grading_scope: @grading_scope,
                                 statuses: row_statuses, submissions: @stack,
                                 tutorials: @tutorials || [])
  end

  # Every answer that swaps a row out sends the line above the table along,
  # rebuilt from the rows, so the two never disagree.
  def summary
    PointingSummaryComponent.new(statuses: row_statuses, hand_ins: !@assignment.kind_test?)
  end

  # A team row speaks for its first member with a participation, as the row
  # itself does; a file without any participation is still to be marked.
  def row_statuses
    from_files = @stack.map do |submission|
      team_participations(submission).compact.first&.display_status || :pending_grading
    end
    return from_files unless grading_enabled?

    from_rows = roster_rows.map do |user, tutorial|
      participation_for(user, tutorial).display_status
    end
    from_files + from_rows
  end

  def tasks
    @assignment&.assessment&.persisted_tasks || []
  end

  # A sheet from before there were points has file rows only.
  def rows?
    @stack.any? ||
      (grading_enabled? && (@non_submitters.any? || @non_tutorial_participants.present?))
  end

  private

    def roster_rows
      entries.reject(&:submission).map { |row| [row.user, row.tutorial] }
    end

    def entries
      @entries ||= @mode == "tutor" ? tutor_entries : teacher_entries
    end

    def tutor_entries
      files = @stack.map { |submission| Row.new(submission: submission) }
      return files unless grading_enabled?

      files + @non_submitters.map { |user| Row.new(user: user, tutorial: @tutorial) }
    end

    def teacher_entries
      @tutorials.flat_map do |tutorial|
        files = (@submissions_by_tutorial[tutorial] || []).map { |s| Row.new(submission: s) }
        next files unless grading_enabled?

        files + (@non_submitters_by_tutorial[tutorial] || []).map do |user|
          Row.new(user: user, tutorial: tutorial)
        end
      end + (grading_enabled? ? @non_tutorial_participants.map { |u| Row.new(user: u) } : [])
    end

    def total_of(row)
      if row.submission
        team_participations(row.submission).compact.first&.points_total
      else
        participation_for(row.user, row.tutorial).points_total
      end
    end

    def sort_key(row)
      total = total_of(row)
      [total.nil? ? 1 : 0, dir == "asc" ? total.to_f : -total.to_f]
    end

    def membership_tutorials
      @membership_tutorials ||=
        TutorialMembership.where(tutorial: @lecture.tutorials).includes(:tutorial)
                          .index_by(&:user_id).transform_values(&:tutorial)
    end
end
