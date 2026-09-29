module CohortsHelper
  def cohort_propagates?(cohort, params)
    if cohort.persisted?
      cohort.propagate_to_lecture?
    else
      propagate_flag = params.dig(:cohort, :propagate_to_lecture)
      propagate_flag != "false"
    end
  end

  # The people a tutorial's tutors are picked from, for a cohort as well, plus
  # the cohort's own tutors: one missing from the options would be dropped
  # from the cohort on the next save.
  def cohort_tutors_preselection(cohort)
    people = (cohort.context.eligible_as_tutors + cohort.tutors).uniq
    options_for_select(people.map { |t| [t.tutorial_info, t.id] }, cohort.tutor_ids)
  end
end
