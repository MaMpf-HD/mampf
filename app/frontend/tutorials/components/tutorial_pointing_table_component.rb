# The pointing table of a sheet: a row for every hand-in and one for everybody
# else on the roster. A tutor sees their group, the lecturer every group.
class TutorialPointingTableComponent < ViewComponent::Base
  def initialize(assignment:, grading_scope: nil)
    super()
    @assignment = assignment
    @lecture = assignment.lecture
    @grading_scope = grading_scope
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
    @participations_by_user_id = preload_participations(@non_submitters, @stack)
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
    @participations_by_user_id =
      preload_participations(@non_submitters.to_a + @non_tutorial_participants.to_a, @stack)

    # Somebody who moved groups after handing in on paper stays with the group
    # that has the sheet; everybody else sits with the group they are in.
    @non_submitters_by_tutorial = @non_submitters.group_by do |user|
      @participations_by_user_id[user.id]&.tutorial || membership_tutorials[user.id]
    end
  end

  # Read once for the whole page; the rows take theirs from here instead of
  # asking per row.
  def preload_participations(non_submitters, submissions)
    return {} unless @assignment.assessment

    user_ids = non_submitters.map(&:id) + submissions.flat_map(&:user_ids)
    Assessment::Participation
      .where(user_id: user_ids, assessment: @assignment.assessment)
      .includes(:task_points, :tutorial, :assessment)
      .index_by(&:user_id)
  end

  def team_participations(submission)
    submission.users.map { |user| @participations_by_user_id[user.id] }
  end

  # Before the backfill worker has been round there is no participation yet;
  # the row is drawn from an unsaved one, and recording the hand-in saves it.
  def participation_for(user, tutorial)
    @participations_by_user_id[user.id] ||
      Assessment::Participation.new(assessment: @assignment.assessment, user: user,
                                    tutorial: tutorial)
  end

  def grading_enabled?
    @assignment.assessable?
  end

  def toolbar
    PointingToolbarComponent.new(assignment: @assignment, grading_scope: @grading_scope,
                                 statuses: row_statuses, submissions: @stack,
                                 tutorials: @tutorials || [])
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

  def total_max_points
    @assignment&.assessment&.effective_total_points || 0
  end

  # A sheet from before there were points has file rows only.
  def rows?
    @stack.any? ||
      (grading_enabled? && (@non_submitters.any? || @non_tutorial_participants.present?))
  end

  private

    def roster_rows
      if @mode == "tutor"
        @non_submitters.map { |user| [user, @tutorial] }
      else
        @non_submitters_by_tutorial.flat_map { |tutorial, users| users.map { |u| [u, tutorial] } } +
          @non_tutorial_participants.map { |user| [user, nil] }
      end
    end

    def membership_tutorials
      @membership_tutorials ||=
        TutorialMembership.where(tutorial: @tutorials).includes(:tutorial)
                          .index_by(&:user_id).transform_values(&:tutorial)
    end
end
