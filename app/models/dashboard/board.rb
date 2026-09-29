module Dashboard
  class Board
    def initialize(user:, term:)
      @user = user
      @term = term
    end

    attr_reader :user, :term

    def staff_lectures
      @staff_lectures ||= lectures_of_term(
        Lecture.where(id: user.given_lectures.select(:id))
               .or(Lecture.where(id: user.edited_lectures.select(:id)))
      )
    end

    # A tutor is one before having a group: by a redeemed voucher or by
    # address. Running a flexible group counts as well, unless the user holds a
    # place in the lecture too: then its card stays with the enrolled ones,
    # which carry what a student needs.
    def tutored_lectures
      @tutored_lectures ||= lectures_of_term(
        Lecture.where(id: user.given_tutorials.select(:lecture_id))
               .or(Lecture.where(id: user.given_cohorts.where(context_type: "Lecture")
                                                   .select(:context_id))
                          .where.not(id: seated_lectures.select(:id)))
               .or(Lecture.where(id: user.tutor_appointments.select(:lecture_id)))
               .or(Lecture.where(id: Voucher.for_tutors
                                            .where(id: user.redemptions.select(:voucher_id))
                                            .select(:lecture_id)))
      ) - staff_lectures
    end

    # The lectures this user holds a place in, or has an open application for
    # (see User#lectures_with_registration_application). A seminar the user
    # only speaks in, without a place on its roster, joins them, so that the
    # talk has a card to sit on.
    def enrolled_lectures
      @enrolled_lectures ||= begin
        speaking = talks.map(&:lecture_id).uniq -
                   (staff_lectures + tutored_lectures).map(&:id)
        enrolled = lectures_of_term(Lecture.where(id: seated_lectures.select(:id))
                                           .or(Lecture.where(id: speaking)))
        statuses = Registration::StatusQuery.new(user, enrolled.map(&:id))
                                            .statuses

        enrolled.sort_by.with_index do |lecture, index|
          [Registration::StatusQuery.sort_priority(statuses[lecture.id]), index]
        end
      end
    end

    def bookmarked_lectures
      @bookmarked_lectures ||= lectures_of_term(user.lectures) -
                               enrolled_lectures - staff_lectures -
                               tutored_lectures
    end

    def talks
      @talks ||= begin
        visible = user.talks.includes(lecture: :term)
                      .select { |talk| talk.visible_for_user?(user) }
        of_term = visible.select { |talk| term && talk.lecture.term_id == term.id }
        independent = visible.select { |talk| talk.lecture.term_id.nil? }
        of_term.sort_by(&:position) + independent.sort_by(&:position)
      end
    end

    # A talk shows on its seminar's card rather than on a card of its own.
    def talks_for(lecture)
      talks.select { |talk| talk.lecture_id == lecture.id }
    end

    def empty?
      [staff_lectures, tutored_lectures, enrolled_lectures,
       bookmarked_lectures].all?(&:empty?)
    end

    def lecture_activity
      @lecture_activity ||= Dashboard::LectureActivity.new(
        user: user,
        lectures: staff_lectures + tutored_lectures + enrolled_lectures +
                  bookmarked_lectures
      )
    end

    private

      # The lectures the user holds a place in or has applied to as a student.
      def seated_lectures
        user.roster_lectures.or(user.lectures_with_registration_application)
      end

      def lectures_of_term(scope)
        independent = scope.where(term: nil).includes(:course, :teacher)
                           .natural_sort_by(&:title)
        return independent if term.nil?

        scope.where(term: term).includes(:course, :term, :teacher)
             .natural_sort_by(&:title) + independent
      end
  end
end
