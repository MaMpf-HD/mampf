module Seeds
  # Makes the lecture the demo opens on look like one that is well under way:
  # tutors in front of the groups, students spread across them, and exercise
  # sheets that were handed in and partly corrected. Anything still being
  # registered for lives in the term after this one.
  module CourseworkSupport
    module_function

    SECOND_TUTOR_EMAIL = "tutor2@mampf.edu".freeze
    NAMED_STUDENT_EMAILS = (1..5).map { |number| "student#{number}@mampf.edu" }.freeze
    # Left behind on the demo lecture by earlier builds, when the campaign
    # playground still ran on it.
    PLAYGROUND_TUTORIAL_TITLES = /\A(FCFS )?Tutorial \d+\z/
    PLAYGROUND_COHORT_TITLES = ["Repeaters", "Waitlist"].freeze
    # What a group hands in per sheet. Also the ceiling, so that a rebuild does
    # not pile more on top of what the last one left.
    TEAMS_PER_TUTORIAL = 2

    def setup!
      lecture = demo_lecture
      return if lecture.nil?

      drop_playground_leftovers!(lecture)
      staff_tutorials!(lecture)
      seat_named_students!(lecture)
      hand_in_sheets!(lecture)
    end

    def demo_lecture
      Lecture.find_by(id: 1)
    end

    # The playground moved to the term that is still being registered for; a
    # rebuild starts from the last dump, so what it left here has to go.
    def drop_playground_leftovers!(lecture)
      Demo::CampaignCleanup.discard_all!(lecture, except: kept_campaign_description)

      Cohort.where(context: lecture, title: PLAYGROUND_COHORT_TITLES).destroy_all

      lecture.tutorials.each do |tutorial|
        next unless tutorial.title.match?(PLAYGROUND_TUTORIAL_TITLES)
        next if tutorial.tutorial_memberships.any? || tutorial.submissions.any?

        tutorial.destroy!
      end
    end

    def kept_campaign_description
      Demo::SetupSupport::LECTURE_CAMPAIGN_DESCRIPTION
    end

    def staff_tutorials!(lecture)
      tutors = [named_user("tutor@mampf.edu"), second_tutor].compact
      return if tutors.empty?

      lecture.tutorials.order(:title).each_with_index do |tutorial, index|
        tutor = tutors[index % tutors.size]
        next if tutor.in?(tutorial.tutors)

        tutorial.tutors << tutor
      end
    end

    # The accounts a developer actually logs in with should sit in a group, so
    # that the submission pages have something to show -- in the group they have
    # been handing in to, where there is one.
    def seat_named_students!(lecture)
      tutorials = seated_tutorials(lecture)
      return if tutorials.empty?

      named_students.each_with_index do |student, index|
        next if TutorialMembership.exists?(lecture: lecture, user: student)

        subscribe!(lecture, student)
        tutorial = tutorial_handed_in_to(lecture, student) ||
                   tutorials[index % tutorials.size]
        TutorialMembership.create!(tutorial: tutorial, user: student)
      end
    end

    def subscribe!(lecture, student)
      return if LectureUserJoin.exists?(lecture: lecture, user: student)

      LectureUserJoin.create!(lecture: lecture, user: student)
    end

    def tutorial_handed_in_to(lecture, student)
      Submission.joins(:users, :assignment)
                .where(assignments: { lecture_id: lecture.id },
                       users: { id: student.id })
                .first&.tutorial
    end

    def hand_in_sheets!(lecture)
      return if manuscript_path.nil?

      lecture.assignments.order(:deadline).each_with_index do |assignment, index|
        seated_tutorials(lecture).each do |tutorial|
          teams_for(tutorial).each_with_index do |team, position|
            corrected = assignment.expired? && position.even?
            hand_in!(assignment, tutorial, team,
                     correction: corrected && (index.zero? ? :accepted : :pending))
          end
        end
      end
    end

    # Two hand in together, the next one alone, and the rest of the group does
    # not hand in at all -- which is what a tutorial looks like.
    def teams_for(tutorial)
      members = tutorial.tutorial_memberships.includes(:user).map(&:user).sort_by(&:id)
      return [] if members.empty?

      teams = [members.first(2), members.drop(2).first(1)]
      teams.reject(&:empty?).first(TEAMS_PER_TUTORIAL)
    end

    def hand_in!(assignment, tutorial, team, correction:)
      return if team.any? { |user| handed_in?(assignment, user) }
      return if Submission.where(assignment: assignment,
                                 tutorial: tutorial).count >= TEAMS_PER_TUTORIAL

      submission = Submission.new(assignment: assignment, tutorial: tutorial,
                                  users: [team.first])
      submission.manuscript = manuscript_copy
      submission.save!
      # A partner joins an existing submission; handing both users to a new one
      # trips the team-size check, which counts what is already in the team.
      team.drop(1).each do |partner|
        UserSubmissionJoin.create!(user: partner, submission: submission)
      end
      return unless correction

      submission.correction = manuscript_copy
      submission.accepted = correction == :accepted
      submission.save!
    end

    # One submission per assignment and person: a team whose member has handed
    # in already is left alone, which is also what makes this rerunnable.
    def handed_in?(assignment, user)
      UserSubmissionJoin.where(user: user, submission: assignment.submissions).any?
    end

    def seated_tutorials(lecture)
      @seated_tutorials ||= {}
      @seated_tutorials[lecture.id] ||=
        lecture.tutorials.order(:title).select { |t| t.tutorial_memberships.any? }
               .presence || lecture.tutorials.order(:title).to_a
    end

    def named_students
      @named_students ||= NAMED_STUDENT_EMAILS.filter_map { |email| named_user(email) }
    end

    def named_user(email)
      User.find_by(email: email)
    end

    def second_tutor
      named_user(SECOND_TUTOR_EMAIL) ||
        FactoryBot.create(:confirmed_user, email: SECOND_TUTOR_EMAIL,
                                           name: "Toni Tutor")
    end

    # A file the seed already ships, so the dump grows by nothing that is not
    # already in it. It is opened again for every hand-in, because Shrine closes
    # what it has uploaded.
    def manuscript_path
      return @manuscript_path if defined?(@manuscript_path)

      source = Medium.where.not(manuscript_data: nil).first
      @manuscript_path = source && write_copy(source.manuscript.download)
    end

    def write_copy(download)
      path = File.join(Dir.mktmpdir, "abgabe.pdf")
      File.binwrite(path, download.read)
      path
    end

    def manuscript_copy
      manuscript_path && File.open(manuscript_path, "rb")
    end
  end
end
