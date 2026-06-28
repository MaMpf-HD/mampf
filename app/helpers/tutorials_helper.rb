# Tutorials Helper
module TutorialsHelper
  def cancel_editing_tutorial_path(tutorial)
    return cancel_edit_tutorial_path(tutorial) if tutorial.persisted?

    cancel_new_tutorial_path(params: { lecture: tutorial.lecture })
  end

  def tutors_preselection(tutorial)
    options_for_select(tutorial.lecture.eligible_as_tutors.map do |t|
                         [t.tutorial_info, t.id]
                       end, tutorial.tutor_ids)
  end

  def tutorials_selection(lecture)
    lecture.tutorials.map { |t| [t.title_with_tutors, t.id] }
  end

  def grading_enabled?(assignment)
    Flipper.enabled?(:assessment_grading) && assignment.assessable?
  end

  def badge_status_participation_color(status)
    {
      pending: "warning",
      reviewed: "success",
      exempt: "info",
      absent: "info"
    }[status&.to_sym]
  end

  def tutorials_for_dropdown(user, lecture, current_tutorial)
    if !user.in?(lecture.tutors)
      {
        "All tutorials" => lecture.tutorials - [current_tutorial]
      }

    elsif user.editor_or_teacher_in?(lecture)
      {
        "Own tutorials" => user.tutorials(lecture) - [current_tutorial],
        "Other tutorials" => lecture.tutorials - user.tutorials(lecture) - [current_tutorial]
      }.delete_if { |_, list| list.empty? }

    else # user is a tutor
      {
        "Your tutorials" => user.tutorials(lecture) - [current_tutorial]
      }
    end
  end

  def overview_info(tutorial, assignment)
    stack = assignment&.submissions&.where(tutorial: tutorial)&.proper
                      &.order(:last_modification_by_users_at)
    non_submitters = assignment.non_submitters_in_tutorial(tutorial)

    num_submissions = stack.size
    num_submissions_with_points = stack.count do |s|
      s.participations && s.participations.first&.status == "reviewed"
    end
    num_submissions_without_points = num_submissions - num_submissions_with_points

    num_non_submitters = non_submitters.size
    num_participated = non_submitters.count do |u|
      u.assessment_participation_in_assignment(assignment)
    end
    num_not_participated = num_non_submitters - num_participated
    num_participated_with_points = non_submitters.count do |u|
      u.assessment_participation_in_assignment(assignment)&.status == "reviewed"
    end
    num_participated_without_points = num_participated - num_participated_with_points

    {
      submissions: {
        total: num_submissions,
        graded: num_submissions_with_points,
        pending: num_submissions_without_points
      },
      non_submitters: {
        total: num_non_submitters,
        participated: num_participated,
        graded: num_participated_with_points,
        pending: num_participated_without_points,
        not_marked: num_not_participated
      }
    }
  end
end
