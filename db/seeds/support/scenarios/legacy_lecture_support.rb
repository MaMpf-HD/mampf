module Demo
  # A lecture the way they ran before the roster: groups with a tutor and
  # nobody seated in them, students who are merely subscribed, and sheets
  # handed in the old way - the group named in the submission and nowhere
  # else, no pointbook behind the sheet. It is what production carries from
  # before Müsli, and it is there so the seat rule can be looked at against
  # it: the archive stays readable, nothing new can be handed in without a
  # seat, and a seat taken later leaves the old hand-ins where they are.
  module LegacyLectureSupport
    extend self

    COURSE_TITLE = "Demo Legacy Lecture".freeze
    TUTORIALS = [["Legacy Mo 14-16", "tutor@mampf.edu"],
                 ["Legacy Do 9-11", "tutor2@mampf.edu"]].freeze
    # The accounts one signs in with come first, so that the page can be
    # looked at as one of them; the rest fill the groups out.
    NAMED_STUDENT_EMAILS = (1..3).map { |number| "student#{number}@mampf.edu" }.freeze
    GENERATED_STUDENTS = 5
    # Two sheets over, one of them marked, and one still open - the states
    # a card can be in, on one page.
    SHEETS = [
      { title: "Legacy Sheet 1", due_in: -3.weeks, corrected: true },
      { title: "Legacy Sheet 2", due_in: -1.week, corrected: false },
      { title: "Legacy Sheet 3", due_in: 1.week, corrected: false }
    ].freeze

    def setup!
      ensure_non_production!
      lecture = ensure_lecture!
      reset!(lecture)
      tutorials = ensure_tutorials!(lecture)
      students = subscribe_students!(lecture)
      sheets = create_sheets!(lecture)
      hand_in!(sheets, tutorials, students)
      report(lecture, tutorials, students)
    end

    private

      # rubocop:disable Rails/Exit
      def ensure_non_production!
        abort("Cannot run in production!") if Rails.env.production?
      end
      # rubocop:enable Rails/Exit

      def ensure_lecture!
        term = Term.active || raise("No active term found. Run just seed first.")
        teacher = User.find_by(email: "teacher@mampf.edu") ||
                  raise("User teacher@mampf.edu not found. Run just seed first.")
        course = Course.find_by(title: COURSE_TITLE) ||
                 FactoryBot.create(:course, title: COURSE_TITLE)
        lecture = Lecture.find_by(course: course, term: term) ||
                  FactoryBot.create(:lecture, course: course, term: term,
                                              teacher: teacher)
        lecture.update!(released: "all", teacher: teacher, locale: "de")
        lecture
      end

      # The sheets and what hangs off them are ours to clear; the lecture, its
      # groups and its subscribers stay, so an id one has bookmarked survives.
      def reset!(lecture)
        lecture.assignments.each do |assignment|
          Submission.where(assignment: assignment).find_each(&:destroy)
          assignment.assessment&.destroy
          assignment.destroy!
        end
      end

      # Groups with a tutor and nobody in them - and nothing else that would
      # make the lecture run a roster: no campaign, no self-service.
      def ensure_tutorials!(lecture)
        TUTORIALS.map do |title, tutor_email|
          tutorial = Tutorial.find_by(lecture: lecture, title: title) ||
                     FactoryBot.create(:tutorial, lecture: lecture, title: title)
          tutor = User.find_by(email: tutor_email)
          tutorial.tutors << tutor if tutor && !tutor.in?(tutorial.tutors)
          tutorial
        end
      end

      def subscribe_students!(lecture)
        students = NAMED_STUDENT_EMAILS.filter_map { |email| User.find_by(email: email) }
        students += (1..GENERATED_STUDENTS).map do |number|
          email = "legacy-student-#{number}@mampf.edu"
          User.find_by(email: email) ||
            FactoryBot.create(:confirmed_user, email: email,
                                               name: "Legacy Student #{number}",
                                               name_in_tutorials: "Legacy Student #{number}")
        end
        students.each do |student|
          next if LectureUserJoin.exists?(lecture: lecture, user: student)

          LectureUserJoin.create!(lecture: lecture, user: student)
        end
        students
      end

      # A deadline in the past is refused on the way in, so it is written
      # afterwards. The pointbook goes: a sheet from before Müsli has none, and
      # with one the page would read the hand-ins as unrecorded rather than as
      # what they are, files from the old system.
      def create_sheets!(lecture)
        SHEETS.map do |attrs|
          assignment = lecture.assignments.create!(title: attrs[:title],
                                                   deadline: 1.year.from_now,
                                                   accepted_file_type: ".pdf")
          # rubocop:disable Rails/SkipsModelValidations
          assignment.update_column(:deadline, attrs[:due_in].from_now)
          # rubocop:enable Rails/SkipsModelValidations
          assignment.assessment&.destroy
          assignment.reload
        end
      end

      # One pair, everybody else alone, spread over the two groups the way a
      # student would have picked them - and nobody in the open sheet yet, so
      # that its card shows what a reader without a seat gets offered.
      def hand_in!(sheets, tutorials, students)
        return if Demo::HandInSupport.manuscript_path.nil?

        teams = [students.first(2)] + students.drop(2).zip
        sheets.zip(SHEETS).each do |assignment, attrs|
          next if attrs[:due_in].positive?

          teams.each_with_index do |team, position|
            correction = attrs[:corrected] && (position.even? ? :accepted : :pending)
            Demo::HandInSupport.hand_in!(
              assignment: assignment, tutorial: tutorials[position % tutorials.size],
              team: team, correction: correction,
              handed_in_at: assignment.deadline - rand(2..72).hours
            )
          end
        end
      end

      def report(lecture, tutorials, students)
        submissions = Submission.joins(:assignment)
                                .where(assignments: { lecture_id: lecture.id })
        $stdout.puts("lecture ##{lecture.id}: #{COURSE_TITLE} " \
                     "(#{lecture.roster_managed? ? "roster" : "no roster"})")
        $stdout.puts("  #{tutorials.size} groups, nobody seated; " \
                     "#{students.size} subscribed, #{NAMED_STUDENT_EMAILS.join(", ")} among them")
        $stdout.puts("  #{lecture.assignments.count} sheets, " \
                     "#{submissions.count} hand-ins the old way, " \
                     "#{submissions.where.not(correction_data: nil).count} of them corrected")
        $stdout.puts("  /lectures/#{lecture.id}/submissions as a student, " \
                     "/lectures/#{lecture.id}/tutorials as a tutor")
      end
  end
end
