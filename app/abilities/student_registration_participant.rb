module StudentRegistrationParticipant
  private

    def student_registration_participant?(user, lecture)
      lecture.visible_for_user?(user) &&
        lecture.in?(user.lectures) &&
        !user.in?(lecture.tutors) &&
        user != lecture.teacher &&
        !user.can_edit?(lecture)
    end
end
