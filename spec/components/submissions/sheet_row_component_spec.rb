require "rails_helper"

RSpec.describe(SheetRowComponent, type: :component) do
  # The design is written in English and so are the numbers in it: the default
  # locale would write 6,5 and compare it against the mockup's 6.5.
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  # The state machine itself is pinned in the loader's spec; what is checked
  # here is the other half - which words, which colour, and whether the row
  # speaks in the points column or in the status column, never in both.
  # `tasks_set_up?` follows the maximum unless it is given: points come from
  # problems, so a sheet worth 16 has them. The two are told apart where it
  # matters - a problem may be set at 0.
  def sheet(state, points: nil, max_points: 16, tasks_set_up: nil,
            friendly_deadline: 15.minutes.from_now)
    assignment = instance_double(Assignment, title: "Homework 8",
                                             friendly_deadline: friendly_deadline)
    scale = max_points.to_f.positive?
    instance_double(Assessment::SubmissionsHub::Sheet,
                    state: state, points: points, max_points: max_points,
                    scale?: scale,
                    tasks_set_up?: tasks_set_up.nil? ? scale : tasks_set_up,
                    assignment: assignment,
                    # The row renders its fold with it; the fold has a spec of
                    # its own, so here it only has to stay out of the way.
                    submission: nil, tasks: [], partners: [],
                    points_for: nil, marked_at: nil, marked_by: nil)
  end

  def render_state(state, **)
    render_inline(described_class.new(sheet: sheet(state, **)))
    rendered_content
  end

  describe "the number and the badge never both speak" do
    it "shows the points and no badge for a marked sheet" do
      content = render_state(:marked, points: 6.5)

      expect(content).to include("6.5")
      expect(content).not_to include("chip")
    end

    # Every sheet has a scale only once somebody sets its problems up, and in
    # that window a 0 either side of the slash says something about the sheet
    # where the truth is about the moment. What decides is the scale, not
    # whether the problems are there: the two part company below.
    it "says nothing in the points column for a missed sheet with no scale" do
      content = render_state(:missed, max_points: 0, tasks_set_up: true)

      expect(content).to include("&mdash;")
      expect(content).to include("num-none")
      expect(content).not_to include("num-zero")
      expect(content).not_to include("/ 0")
      expect(content).to include(I18n.t("submission.hub.notes.missed"))
    end

    it "still counts what a missed sheet was worth when it was worth something" do
      content = render_state(:missed, points: 0, max_points: 8)

      expect(content).to include("num-zero")
      expect(content).to include("/ 8")
    end

    # `Assessment::TaskPoint` puts no ceiling on what a tutor may award, so a
    # sheet whose problems are worth nothing can still carry points. They are
    # the reader's; it is the denominator that has nothing to say.
    it "shows points a sheet carries even where there is no scale for them" do
      content = render_state(:marked, points: 2, max_points: 0,
                                      tasks_set_up: true)

      expect(content).to include("2")
      expect(content).not_to include("/ 0")
      expect(content).to include(
        I18n.t("submission.hub.points_reader_no_max", points: "2")
      )
      expect(content).not_to include(
        I18n.t("submission.hub.points_reader", points: "2", max: "0")
      )
    end

    it "shows a badge and no number where nothing can be shown" do
      content = render_state(:awaiting_marks)

      expect(content).to include(I18n.t("submission.hub.chips.awaiting_marks"))
      expect(content).to include("num-none")
      expect(content).not_to include("num-zero")
    end
  end

  describe "the badges" do
    {
      nothing_handed_in: "chip-act",
      handed_in: "chip-wait",
      tutor_decides: "chip-act",
      awaiting_marks: "chip-wait",
      correction_uploaded: "chip-wait",
      exempt: "chip-wait"
    }.each do |state, tone|
      it "gives #{state} the #{tone} badge" do
        content = render_state(state)

        expect(content).to include(tone)
        expect(content).to include(I18n.t("submission.hub.chips.#{state}"))
      end
    end

    it "counts down the grace period in the badge and the note" do
      content = render_state(:grace_period,
                             friendly_deadline: 15.minutes.from_now)

      expect(content).to include("chip-act")
      expect(content).to include("15 minutes")
      expect(content).to include(
        I18n.t("submission.hub.notes.grace_period", time: "15 minutes")
      )
    end

    it "never uses the lost colour, which the list has nothing to say with" do
      content = render_state(:rejected, points: 0)

      expect(content).not_to include("chip-lost")
    end
  end

  describe "the quiet line under the name" do
    it "explains a zero that was nobody's doing in red" do
      content = render_state(:not_recorded, points: 0)

      expect(content).to include("sheet-note-bad")
      expect(content).to include(I18n.t("submission.hub.notes.not_recorded"))
    end

    it "explains a rejected late hand-in in red" do
      content = render_state(:rejected, points: 0)

      expect(content).to include("sheet-note-bad")
      expect(content).to include(I18n.t("submission.hub.notes.rejected"))
    end

    # The number is the whole story for a marked sheet; that it was handed in
    # late and let through changes nothing about it.
    it "says nothing under a marked sheet" do
      content = render_state(:marked, points: 6.5)

      expect(content).not_to include("sheet-note")
    end

    it "says that a partly marked sheet is not finished" do
      content = render_state(:partially_marked, points: 5.5)

      expect(content).to include("5.5")
      expect(content).not_to include("chip")
      expect(content)
        .to include(I18n.t("submission.hub.notes.partially_marked"))
    end
  end

  describe "the points column" do
    it "writes a zero in red where the sheet counts as nothing" do
      content = render_state(:missed, points: 0)

      expect(content).to include("num-zero")
      expect(content).to include(I18n.t("submission.hub.notes.missed"))
    end

    it "drops the denominator for an excused sheet, which no longer counts" do
      content = render_state(:exempt)

      expect(content).not_to include("/ 16")
      expect(content).to include(I18n.t("submission.hub.chips.exempt"))
    end

    it "draws the bar as a share of the maximum" do
      content = render_state(:marked, points: 6.5, max_points: 16)

      expect(content).to include("width: 40.63%")
    end

    it "draws no bar where there is no maximum to divide by" do
      content = render_state(:marked, points: 0, max_points: 0)

      expect(content).not_to include("spark")
    end
  end

  describe "accessibility" do
    # Screen readers get "6.5 of 16 points", not "6.5 slash 16".
    it "spells the number out for a reader and hides the figure" do
      content = render_state(:marked, points: 6.5, max_points: 16)

      expect(content).to include(
        I18n.t("submission.hub.points_reader", points: "6.5", max: "16")
      )
      expect(content).to include("aria-hidden=\"true\"")
    end

    it "says in words what the dimming of an old sheet means" do
      content = render_state(:no_points)

      expect(content).to include(I18n.t("submission.hub.old_style"))
      expect(content).to include(I18n.t("submission.hub.no_points"))
      expect(content).to include("sheet-muted")
    end
  end
end
