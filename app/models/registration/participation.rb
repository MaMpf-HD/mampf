module Registration
  # The abilities that authorize registration and the pages that offer it ask
  # this same question, so that the two cannot give different answers.
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
