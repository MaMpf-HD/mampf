module Registration
  # Asked by the abilities that authorize registration and by the pages that
  # offer it, so that the two cannot give different answers.
  #
  # Neither a subscription nor the passphrase is asked for: registering is not
  # access, and roster members get theirs from Lecture#ensure_roster_membership!.
  module Participation
    module_function

    def allowed?(user, lecture)
      return false if user.blank? || lecture.blank?

      lecture.published? &&
        !user.in?(lecture.tutors) &&
        user != lecture.teacher &&
        !user.can_edit?(lecture)
    end
  end
end
