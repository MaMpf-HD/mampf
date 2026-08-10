module StudentRegistrationParticipant
  private

    # A student may take part in registration for a lecture if the lecture is
    # published and they are not part of the lecture's staff.
    #
    # Note that deliberately neither a subscription nor a passphrase is
    # required: registration is decoupled from content access (subscription),
    # so that students can register for lectures whose content is gated by a
    # passphrase. Content access for confirmed roster members is granted
    # separately (see Lecture#ensure_roster_membership!).
    def student_registration_participant?(user, lecture)
      lecture.published? &&
        !user.in?(lecture.tutors) &&
        user != lecture.teacher &&
        !user.can_edit?(lecture)
    end
end
