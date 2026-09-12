# The pointing table of a sheet: one row for every hand-in of a group and one
# for everybody else on its roster, so that a sheet taken on paper, a missing
# one and an excused one are rows like any other rather than a list beneath
# the table. A tutor sees their group, the lecturer every group.
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
    # has the sheet, not among those in no group.
    @non_tutorial_participants = @assignment.applicable_users_not_in_tutorials
                                            .where.not(id: @non_submitters.map(&:id))
    @participations_by_user_id =
      preload_participations(@non_submitters.to_a + @non_tutorial_participants.to_a, @stack)

    # Somebody who moved groups after handing in on paper stays with the group
    # that has the sheet; everybody else sits with the group they are in.
    @non_submitters_by_tutorial = @non_submitters.group_by do |user|
      @participations_by_user_id[user.id]&.tutorial || membership_tutorials[user.id]
    end
  end

  # One query for everybody on the page, marks included: the rows read theirs
  # off this rather than asking per row.
  def preload_participations(non_submitters, submissions)
    return {} unless @assignment.assessment

    user_ids = non_submitters.map(&:id) + submissions.flat_map(&:user_ids)
    Assessment::Participation
      .where(user_id: user_ids, assessment: @assignment.assessment)
      .includes(:task_points, :tutorial)
      .index_by(&:user_id)
  end

  def team_participations(submission)
    submission.users.map { |user| @participations_by_user_id[user.id] }
  end

  # The row of somebody without a hand-in. Before the backfill worker has
  # been round there is no participation yet; the row is drawn from an unsaved
  # one, and the first thing written to it - a paper hand-in, points - makes
  # it real.
  def participation_for(user, tutorial)
    @participations_by_user_id[user.id] ||
      Assessment::Participation.new(assessment: @assignment.assessment, user: user,
                                    tutorial: tutorial)
  end

  def grading_enabled?
    @assignment.assessable?
  end

  def tasks
    @assignment&.assessment&.persisted_tasks || []
  end

  def total_max_points
    @assignment&.assessment&.effective_total_points || 0
  end

  def can_enter_points?
    user = helpers.current_user
    user.admin? || user.can_enter_points_in?(@grading_scope)
  rescue User::IncompatibleTypeError
    false
  end

  def rows?
    @stack.any? || @non_submitters.any? || @non_tutorial_participants.present?
  end

  def column_count
    if @mode == "tutor"
      7 + tasks.count
    else
      6 + tasks.count
    end
  end

  private

    def membership_tutorials
      @membership_tutorials ||=
        TutorialMembership.where(tutorial: @tutorials).includes(:tutorial)
                          .index_by(&:user_id).transform_values(&:tutorial)
    end
end
