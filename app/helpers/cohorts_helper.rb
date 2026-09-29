module CohortsHelper
  def cohort_propagates?(cohort, params)
    if cohort.persisted?
      cohort.propagate_to_lecture?
    else
      propagate_flag = params.dig(:cohort, :propagate_to_lecture)
      propagate_flag != "false"
    end
  end

  # The people a tutorial's tutors are picked from, for a cohort as well.
  def cohort_tutors_preselection(cohort)
    options_for_select(cohort.context.eligible_as_tutors.map { |t| [t.tutorial_info, t.id] },
                       cohort.tutor_ids)
  end
end
