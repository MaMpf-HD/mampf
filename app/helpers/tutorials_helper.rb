# Tutorials Helper
module TutorialsHelper
  def cancel_editing_tutorial_path(tutorial)
    return cancel_edit_tutorial_path(tutorial) if tutorial.persisted?
    cancel_new_tutorial_path(params: { lecture: tutorial.lecture })
  end

  def tutorial_preselection(tutorial)
    return [[]] unless tutorial.persisted? && tutorial.tutors.any?
    options_for_select(tutorial.tutors.map { |t| [t.tutorial_info, t.id] },
                       tutorial.tutor_ids)
  end

  def tutorials_selection(lecture)
  	lecture.tutorials.map { |t| [t.title_with_tutors, t.id] }
  end
end
