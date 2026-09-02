require "rails_helper"

RSpec.describe(SheetFoldComponent, type: :component) do
  # The design is written in English and so are its numbers and dates.
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  def task(description: nil, max_points: 4)
    instance_double(Assessment::Task, description: description,
                                      max_points: max_points)
  end

  def handed_in_file(manuscript: nil, correction: nil, at: nil)
    instance_double(Submission, manuscript_filename: manuscript,
                                correction_filename: correction,
                                last_modification_by_users_at: at,
                                created_at: at, to_param: "a-submission")
  end

  def sheet_defaults
    { points_by_task: {}, submission: nil, points: nil, max_points: 16,
      partners: [], marked_at: nil, marked_by: nil }
  end

  def sheet(state, **overrides)
    attrs = sheet_defaults.merge(overrides)
    points_by_task = attrs[:points_by_task]
    double = instance_double(Assessment::SubmissionsHub::Sheet,
                             state: state, submission: attrs[:submission],
                             tasks: points_by_task.keys, points: attrs[:points],
                             max_points: attrs[:max_points],
                             partners: attrs[:partners],
                             marked_at: attrs[:marked_at],
                             marked_by: attrs[:marked_by])
    allow(double).to(receive(:points_for) { |asked| points_by_task[asked] })
    double
  end

  def render_fold(...)
    render_inline(described_class.new(sheet: sheet(...)))
    rendered_content
  end

  describe "points per problem" do
    it "lists every task with its own number" do
      first = task(description: "Convergence", max_points: 4)
      second = task(description: "Compactness", max_points: 6)

      content = render_fold(:marked, points_by_task: { first => 1.5,
                                                       second => 3 })

      expect(content).to include("Convergence")
      expect(content).to include("Compactness")
      expect(content).to include(
        I18n.t("submission.hub.points_reader", points: "1.5", max: "4")
      )
      expect(content).to include(
        I18n.t("submission.hub.points_reader", points: "3", max: "6")
      )
    end

    it "numbers a task that carries no description of its own" do
      content = render_fold(:marked, points_by_task: { task => 2 })

      expect(content).to include(
        I18n.t("submission.hub.fold.problem", number: 1)
      )
    end

    it "draws each bar as a share of that task's maximum" do
      content = render_fold(:marked,
                            points_by_task: { task(max_points: 4) => 1 })

      expect(content).to include("width: 25.0%")
    end

    # A sheet is listed problem by problem as soon as one problem carries a
    # value, so the unmarked ones share the list. Written as a 0 they would say
    # "you scored nothing here".
    it "writes a dash, not a zero, for a problem nobody has marked" do
      marked = task(max_points: 4)
      unmarked = task(max_points: 4)

      content = render_fold(:partially_marked,
                            points_by_task: { marked => 1.5, unmarked => nil })

      expect(content).to include("—")
      expect(content).not_to include(
        I18n.t("submission.hub.points_reader", points: "0", max: "4")
      )
    end

    # And in words, not only in the picture.
    it "tells a reader that the problem is unmarked, not that it scored 0" do
      unmarked = task(max_points: 4)

      content = render_fold(:partially_marked,
                            points_by_task: { task => 1.5, unmarked => nil })

      expect(content).to include(
        I18n.t("submission.hub.fold.problem_unmarked", max: "4")
      )
    end

    it "draws no bar for a problem nobody has marked" do
      unmarked = task(max_points: 4)

      content = render_fold(:partially_marked,
                            points_by_task: { unmarked => nil })

      expect(content).not_to include("spark-wide")
    end

    it "shows the numbers of a half-marked sheet, not a sentence" do
      content = render_fold(:partially_marked,
                            points_by_task: { task => 1.5, task => nil })

      expect(content).to include("1.5")
      expect(content)
        .not_to include(I18n.t("submission.hub.fold.no_points.nothing_yet"))
    end

    {
      no_points: "legacy",
      exempt: "exempt",
      missed: "zero",
      not_recorded: "zero",
      rejected: "zero",
      absent: "zero",
      correction_uploaded: "on_the_correction",
      awaiting_marks: "nothing_yet",
      handed_in: "nothing_yet"
    }.each do |state, reason|
      it "says '#{reason}' rather than numbers for #{state}" do
        content = render_fold(state, max_points: 16)

        expect(content).to include(
          I18n.t("submission.hub.fold.no_points.#{reason}", max: "16")
        )
      end
    end
  end

  describe "the files" do
    # The gap this closes: between the list and the new action card there was no
    # way back to one's own PDFs.
    it "links to what was handed in and to what came back" do
      content = render_fold(
        :marked,
        points_by_task: { task => 2 },
        submission: handed_in_file(manuscript: "homework8.pdf",
                                   correction: "correction.pdf")
      )

      expect(content).to include("homework8.pdf")
      expect(content).to include("correction.pdf")
      expect(content).to include("/submissions/a-submission/show_manuscript")
      expect(content).to include("/submissions/a-submission/show_correction")
    end

    # Both files are often called the same thing. The word in front tells them
    # apart, and it has to be in the link's own name too - somebody walking the
    # links hears nothing else.
    it "names each file link for a reader who cannot see where it stands" do
      content = render_fold(
        :marked,
        points_by_task: { task => 2 },
        submission: handed_in_file(manuscript: "homework8.pdf",
                                   correction: "homework8.pdf")
      )

      expect(content).to include(
        "aria-label=\"#{I18n.t("submission.hub.fold.handed_in_label")}: homework8.pdf\""
      )
      expect(content).to include(
        "aria-label=\"#{I18n.t("submission.hub.fold.correction_label")}: homework8.pdf\""
      )
    end

    # A line that is there and empty says more than a line that is missing.
    it "keeps both lines even where a file is missing" do
      content = render_fold(:missed)

      expect(content).to include(I18n.t("submission.hub.fold.handed_in_label"))
      expect(content).to include(I18n.t("submission.hub.fold.correction_label"))
      expect(content).to include(I18n.t("submission.hub.fold.no_file"))
      expect(content)
        .to include(I18n.t("submission.hub.fold.not_uploaded_yet"))
    end

    it "says so when no file was uploaded at all" do
      content = render_fold(:missed)

      expect(content).to include(I18n.t("submission.hub.fold.no_file"))
    end
  end

  # Behind the line they belong to, rather than as two sentences underneath.
  describe "the times, which stand here and nowhere else" do
    it "puts the hand-in time behind the file" do
      at = Time.zone.local(2026, 8, 15, 16, 27)

      content = render_fold(:awaiting_marks,
                            submission: handed_in_file(manuscript: "hw.pdf",
                                                       at: at))

      expect(content).to include(I18n.l(at, format: :file_time))
    end

    # The only time we have for a marked sheet is when the points were typed,
    # and that is a different event from the scan being uploaded - often days
    # apart. Until the upload has a timestamp of its own, the correction line
    # says nothing about when, rather than something wrong.
    it "keeps the marking time away from the correction" do
      typed = Time.zone.local(2026, 8, 16, 9, 0)
      tutor = instance_double(User, tutorial_name: "Dr. Tutor")

      content = render_fold(:marked, points_by_task: { task => 2 },
                                     marked_at: typed, marked_by: tutor,
                                     submission: handed_in_file(correction: "c.pdf",
                                                                at: nil))

      expect(content).to include("c.pdf")
      expect(content).not_to include(I18n.l(typed, format: :file_time))
      expect(content).not_to include("Dr. Tutor")
    end
  end

  describe "the team" do
    let(:partner) { instance_double(User, tutorial_name: "student2") }

    # One submission, two people, two numbers.
    it "says whose the points on this row are" do
      content = render_fold(:marked, points_by_task: { task => 2 },
                                     points: 6.5, partners: [partner])

      expect(content).to include(
        I18n.t("submission.hub.fold.team_with_points", names: "student2",
                                                       points: "6.5")
      )
    end

    it "names the team without claiming points that are not there" do
      content = render_fold(:awaiting_marks, partners: [partner])

      expect(content).to include(
        I18n.t("submission.hub.fold.team", names: "student2")
      )
    end

    it "says nothing about a team of one" do
      content = render_fold(:awaiting_marks)

      expect(content).not_to include("Team:")
    end
  end
end
