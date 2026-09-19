# Tutorials Helper
module TutorialsHelper
  def cancel_editing_tutorial_path(tutorial)
    return cancel_edit_tutorial_path(tutorial) if tutorial.persisted?

    cancel_new_tutorial_path(params: { lecture: tutorial.lecture })
  end

  # An option knows whether its person is enrolled in the tutorial: the
  # form asks before making them tutor of their own group.
  def tutors_preselection(tutorial)
    enrolled = tutorial.member_ids.to_set
    options_for_select(tutorial.lecture.eligible_as_tutors.map do |t|
                         [t.tutorial_info, t.id, { data: { enrolled: enrolled.include?(t.id) } }]
                       end, tutorial.tutor_ids)
  end

  def grading_enabled?(assignment)
    assignment.assessable?
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
end
