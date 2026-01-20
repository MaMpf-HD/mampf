module CohortsHelper
  def cohort_propagates?(cohort, params)
    if cohort.persisted?
      cohort.propagate_to_lecture?
    else
      propagate_flag = params.dig(:cohort, :propagate_to_lecture)
      propagate_flag.to_s == "true"
    end
  end

  def cohort_special_purpose_type(propagates)
    propagates ? "enrollment" : "planning"
  end

  def cohort_has_special_purpose?(cohort, special_purpose)
    current_purpose = cohort.purpose.to_s.presence || "general"
    current_purpose == special_purpose
  end

  def show_enrollment_warning?(cohort, propagates)
    propagates && (cohort.context.tutorials.any? || cohort.context.talks.any?)
  end
end
