module Demo
  # Handing one sheet in: a submission with a manuscript on it, the partners
  # who join the team, and the correction if the tutor has got to it.
  #
  # Two places stage hand-ins and they want different things around this --
  # the seed build covers the lecture's own sheets, the demo setup covers the
  # ones with an assessment behind them, with their own teams, their own
  # corrections and their own dates. What happens per hand-in is the same, and
  # was written twice before it lived here.
  module HandInSupport
    module_function

    # Below this a manuscript in the seed is a placeholder rather than a
    # document; above it, the smallest one is an exercise sheet.
    MIN_SHEET_BYTES = 10 * 1024

    # `handed_in_at` dates the submission back: a hand-in counts as late by the
    # hour it was written, and these are written today, long after the
    # deadlines they belong to.
    def hand_in!(assignment:, tutorial:, team:, correction: nil,
                 handed_in_at: nil)
      submission = Submission.new(assignment: assignment, tutorial: tutorial,
                                  users: [team.first])
      submission.manuscript = manuscript_copy
      submission.save!
      stamp!(submission, handed_in_at) if handed_in_at
      # A partner joins the existing submission; handing both to a new one
      # trips the team-size check, which counts what is already in the team.
      team.drop(1).each do |partner|
        UserSubmissionJoin.create!(user: partner, submission: submission)
      end
      record_hand_in!(assignment, team, submission)
      return submission unless correction

      submission.correction = manuscript_copy
      submission.accepted = correction == :accepted
      submission.save!
      submission
    end

    # What the controller does on every upload: the gradebook learns that the
    # sheet was handed in. Without it the demo builds a state that is real but
    # rare - a file on record with no hand-in against it, which the student's
    # page has to flag in red - and builds it by the dozen. A sheet without an
    # assessment behind it has nothing to tell, which is the old way and what
    # the lecture's own sheets are.
    #
    # Only the stamp, and only where it is missing: the statuses and points were
    # dealt beforehand and are what the demo is for. Absent and exempt are left
    # alone - `Assessment::AbsenceHandling` clears `submitted_at` on purpose
    # when it sets them, and writing it back would undo that.
    def record_hand_in!(assignment, team, submission)
      participations = assignment.assessment&.assessment_participations
      return unless participations

      # Nothing here goes through the controller, so nobody has written the
      # modification time a hand-in would otherwise be dated by.
      handed_in_at = submission.last_modification_by_users_at ||
                     submission.created_at
      # rubocop:disable Rails/SkipsModelValidations
      participations.where(user_id: team.map(&:id), submitted_at: nil)
                    .where.not(status: [:absent, :exempt])
                    .update_all(submitted_at: handed_in_at,
                                updated_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations
    end

    # A file the seed already ships, so the dump grows by nothing that is not
    # already in it -- and the smallest of them, because the archive beside the
    # dump carries a copy per hand-in.
    def manuscript_path
      return @manuscript_path if defined?(@manuscript_path)

      source = smallest_document
      @manuscript_path = source && write_copy(source.manuscript.download)
    end

    # One copy on disk, opened again per hand-in, because Shrine closes what it
    # has uploaded.
    def manuscript_copy
      manuscript_path && File.open(manuscript_path, "rb")
    end

    def smallest_document
      documents = Medium.where.not(manuscript_data: nil)
                        .select do |medium|
        medium.manuscript.size.to_i >= MIN_SHEET_BYTES
      end
      documents.min_by { |medium| medium.manuscript.size.to_i }
    end

    def write_copy(download)
      path = File.join(Dir.mktmpdir, "abgabe.pdf")
      File.binwrite(path, download.read)
      path
    end

    def stamp!(submission, handed_in_at)
      # rubocop:disable Rails/SkipsModelValidations
      submission.update_columns(created_at: handed_in_at,
                                last_modification_by_users_at: handed_in_at)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
