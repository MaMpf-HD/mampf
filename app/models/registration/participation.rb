module Registration
  # Who takes part in a lecture's registration as a student: everyone but the
  # people who run it. Asked by the abilities that authorize the actions and by
  # the views that offer them, so that the two cannot say different things.
  #
  # Note that deliberately neither a subscription nor a passphrase is
  # required: registration is decoupled from content access (subscription),
  # so that students can register for lectures whose content is gated by a
  # passphrase. Content access for confirmed roster members is granted
  # separately (see Lecture#ensure_roster_membership!).
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
