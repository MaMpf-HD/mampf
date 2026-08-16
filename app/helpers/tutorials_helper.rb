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

  # What is left to grade. Absent and excused participations are settled, so
  # they leave the count entirely — but they are reported, because a tutor who
  # only reads the box would otherwise not find them again in the table.
  def overview_info(tutorial, assignment)
    submissions = assignment&.submissions&.where(tutorial: tutorial)&.proper.to_a
    non_submitters = assignment.non_submitters_in_tutorial(tutorial).to_a

    statuses = submissions.map { |s| s.participations&.first&.status }
    marked = 0

    non_submitters.each do |user|
      participation = user.assessment_participation_in_assignment(assignment)
      next unless participation

      marked += 1
      statuses << participation.status
    end

    absent = statuses.count("absent")
    exempt = statuses.count("exempt")
    graded = statuses.count("reviewed")
    gradable = statuses.size - absent - exempt

    { gradable: gradable,
      graded: graded,
      open: gradable - graded,
      unmarked: non_submitters.size - marked,
      absent: absent,
      exempt: exempt,
      percent: gradable.positive? ? (100.0 * graded / gradable).round : 0 }
  end
end
