module CohortsHelper
  def cohort_propagates?(cohort, params)
    if cohort.persisted?
      cohort.propagate_to_lecture?
    else
      propagate_flag = params.dig(:cohort, :propagate_to_lecture)
      propagate_flag != "false"
    end
  end

  def show_enrollment_warning?(cohort, propagates)
    propagates && (cohort.context.tutorials.exists? || cohort.context.talks.exists?)
  end
end
