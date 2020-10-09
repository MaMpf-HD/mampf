# Tutorials Helper
module TutorialsHelper
  def cancel_editing_tutorial_path(tutorial)
    return cancel_edit_tutorial_path(tutorial) if tutorial.persisted?
    cancel_new_tutorial_path(params: { lecture: tutorial.lecture })
  end

  def tutorial_preselection(tutorial)
    return [[]] unless tutorial.persisted? && tutorial.tutor
    options_for_select([[tutorial.tutor.tutorial_info, tutorial.tutor_id]],
                       tutorial.tutor_id)
  end

  def tutorials_selection(lecture)
  	lecture.tutorials.map { |t| [t.title_with_tutor, t.id] }
  end
end
