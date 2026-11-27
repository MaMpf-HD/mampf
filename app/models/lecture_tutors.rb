# The lectures a user tutors.
module LectureTutors
  module_function

  # Via given tutorials, tutor appointments, or redeemed vouchers.
  def lectures_of(user)
    Lecture.where(id: user.given_tutorials.select(:lecture_id))
           .or(Lecture.where(id: user.tutor_appointments.select(:lecture_id)))
           .or(Lecture.where(id: Voucher.for_tutors
                                        .where(id: user.redemptions.select(:voucher_id))
                                        .select(:lecture_id)))
  end

  # Via given cohorts.
  def cohort_lectures_of(user)
    Lecture.where(id: user.given_cohorts.where(context_type: "Lecture")
                                        .select(:context_id))
  end
end
