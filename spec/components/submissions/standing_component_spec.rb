require "rails_helper"

RSpec.describe(StandingComponent, type: :component) do
  # The design is written in English, and so are its numbers.
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  # `max` is what the term will hold once every sheet is in - the block only
  # ever asks it whether a threshold can still be reached. What it measures by
  # is `due`, below.
  def record_defaults
    { total: 32.5, max: 176, met: [], ungraded: [] }
  end

  def record(**overrides)
    attrs = record_defaults.merge(overrides)
    instance_double(StudentPerformance::Record,
                    points_total_materialized: attrs[:total],
                    points_max_materialized: attrs[:max],
                    achievements_met_ids: attrs[:met],
                    achievements_ungraded_ids: attrs[:ungraded])
  end

  def achievement(title: "Blackboard Talk", id: 1, value_type: :boolean,
                  threshold: nil)
    instance_double(Achievement, id: id, title: title, threshold: threshold,
                                 boolean?: value_type == :boolean,
                                 percentage?: value_type == :percentage)
  end

  # `due` is the sheets that are actually behind the reader - what the block
  # measures by; it defaults to the term's total so that an example which does
  # not care about the difference reads as it always did.
  def standing_defaults
    { rule: nil, achievements: [], values: {}, eligibility: true,
      still_open: 0, due: 176, awaiting: 16, awaiting_sheets: 2,
      complete: true }
  end

  def standing(**overrides)
    attrs = standing_defaults.merge(overrides)
    record_options = overrides.except(*standing_defaults.keys)
    Assessment::SubmissionsHub::Standing.new(
      record: record(**record_options), rule: attrs[:rule],
      achievement_values: attrs[:values], points_still_open: attrs[:still_open],
      points_due: attrs[:due], points_awaiting_marks: attrs[:awaiting],
      sheets_awaiting_marks: attrs[:awaiting_sheets],
      assignments_complete: attrs[:complete],
      uses_exam_eligibility: attrs[:eligibility]
    ).tap do |built|
      allow(built).to receive(:required_achievements)
        .and_return(attrs[:achievements])
    end
  end

  # The double answers `required_points` the way the rule does, out of whatever
  # maximum it is asked with - which is the whole point of the argument: the
  # mark asks with the points due, the reachability test with the term's total.
  def rule(mode, percentage: nil, absolute: nil)
    built = instance_double(StudentPerformance::Rule,
                            threshold_mode_percentage?: mode == :percentage,
                            threshold_mode_absolute?: mode == :absolute,
                            min_percentage: percentage,
                            min_points_absolute: absolute)
    allow(built).to receive(:required_points) do |max|
      case mode
      when :percentage then (percentage * max / 100).round(2) if max.to_f.positive?
      when :absolute then absolute
      end
    end
    built
  end

  def render_standing(built)
    render_inline(described_class.new(standing: built))
    rendered_content
  end

  describe "the points and the bar" do
    # The base belongs in the line. Measured against every sheet the lecture has
    # set up, a reader with full marks on the two that came back reads as 64 %,
    # which is a statement about the calendar.
    it "says what has been earned of what has come due" do
      content = render_standing(standing(total: 34, due: 36))

      expect(content).to include("34")
      expect(content)
        .to include(I18n.t("submission.hub.standing.of_due", max: "36"))
      expect(content).not_to include(
        I18n.t("submission.hub.standing.of_due", max: "176")
      )
    end

    it "takes the share of what is due, not of what the term will hold" do
      content = render_standing(standing(total: 36, due: 36, max: 56))

      expect(content).to include("width: 100.0%")
    end

    it "fills the bar with the share earned" do
      content = render_standing(standing)

      expect(content).to include("width: 18.47%")
    end

    # A bar without a scale claims a ratio that does not exist.
    it "draws no bar while nothing has come due yet" do
      content = render_standing(standing(due: 0))

      expect(content).not_to include("standing-bar")
      expect(content)
        .to include(I18n.t("submission.hub.standing.no_max"))
    end

    it "says so while nothing has been marked at all" do
      content = render_standing(standing(total: nil))

      expect(content)
        .to include(I18n.t("submission.hub.standing.nothing_marked"))
    end

    # Where the number sits is the whole question a reader has here: "16 points
    # are still being marked" leaves them guessing whether the 16 are in their
    # total already. Said against the points due, they are - and the sheets are
    # named so that the number has something to belong to.
    it "says how much is waiting, and of what" do
      content = render_standing(standing(due: 176, awaiting: 16,
                                         awaiting_sheets: 2))

      expect(content).to include(
        I18n.t("submission.hub.standing.awaiting_marks", count: 2,
                                                         points: "16",
                                                         max: "176")
      )
    end

    it "counts a single sheet in the singular" do
      content = render_standing(standing(awaiting: 8, awaiting_sheets: 1))

      expect(content).to include(
        I18n.t("submission.hub.standing.awaiting_marks", count: 1, points: "8",
                                                         max: "176")
      )
    end

    it "says nothing about waiting sheets when none are" do
      content = render_standing(standing(awaiting: 0, awaiting_sheets: 0))

      expect(content).not_to include("not marked yet")
    end
  end

  describe "a percentage rule" do
    let(:percentage_rule) { rule(:percentage, percentage: 50) }

    it "names the threshold in the words the rule was written in" do
      content = render_standing(standing(rule: percentage_rule))

      expect(content).to include(
        I18n.t("submission.hub.standing.condition_percentage", percentage: "50")
      )
      expect(content).to include(
        I18n.t("submission.hub.standing.you_have_percent", percentage: "18.47")
      )
    end

    # Bar and mark are the same quantity now - both shares of what is due - so
    # the mark is the rule's own number and needs no converting.
    it "marks the rule's own percentage" do
      content = render_standing(standing(rule: percentage_rule))

      expect(content).to include("left: 50.0%")
      expect(content).to include(
        I18n.t("submission.hub.standing.mark_percentage", percentage: "50")
      )
    end

    # The points behind the mark move with what is due, so they are said where
    # they can be looked up rather than on the mark itself.
    it "puts the points behind the mark in the title, out of what is due" do
      content = render_standing(standing(rule: percentage_rule, due: 36))

      expect(content).to include(
        "title=\"#{I18n.t("submission.hub.standing.needed", points: "18")}\""
      )
    end
  end

  describe "an absolute rule" do
    let(:absolute_rule) { rule(:absolute, absolute: 90) }

    # There the number is the rule, so the bar runs to it and its end is the
    # threshold - a full bar means the condition is met, the same reading as
    # under a percentage rule. A mark would sit on that end and say nothing.
    it "counts towards the number the rule names, and carries no mark" do
      content = render_standing(standing(rule: absolute_rule, total: 45,
                                         due: 36))

      expect(content)
        .to include(I18n.t("submission.hub.standing.of_needed", max: "90"))
      expect(content).to include("width: 50.0%")
      expect(content).not_to include("standing-mark")
    end

    it "names the threshold in points and says what the reader has" do
      content = render_standing(standing(rule: absolute_rule, total: 104.5))

      expect(content).to include(
        I18n.t("submission.hub.standing.condition_absolute", points: "90")
      )
      expect(content).to include(
        I18n.t("submission.hub.standing.you_have_points", points: "104.5")
      )
    end
  end

  describe "without a rule" do
    it "keeps the points and says the conditions are not set yet" do
      content = render_standing(standing)

      expect(content).to include("32.5")
      expect(content)
        .to include(I18n.t("submission.hub.standing.no_conditions"))
    end

    # Taking the block away would take its main job with it.
    it "keeps the points where the lecture runs no admission at all" do
      content = render_standing(standing(eligibility: false))

      expect(content).to include("32.5")
      expect(content)
        .to include(I18n.t("submission.hub.standing.no_conditions"))
    end
  end

  describe "the conditions that are not points" do
    let(:talk) { achievement }
    let(:attendance) do
      achievement(title: "Attendance Rate", id: 2, value_type: :percentage,
                  threshold: 80)
    end

    # A rule may ask for achievements and no points at all; then the block shows
    # those lines and no threshold.
    let(:achievements_only) { rule(:none) }

    it "says passed for one the record counts as met" do
      built = standing(rule: achievements_only, achievements: [talk], met: [1])

      expect(render_standing(built))
        .to include(I18n.t("submission.hub.standing.passed"))
    end

    it "says not recorded yet for one nobody has graded" do
      built = standing(rule: achievements_only, achievements: [talk],
                       ungraded: [1])

      expect(render_standing(built))
        .to include(I18n.t("submission.hub.standing.not_recorded"))
    end

    # No record at all is not the same as a condition that was graded and fell
    # short, and the block must not show it as one.
    it "says not recorded yet for a reader who has no record at all" do
      built = Assessment::SubmissionsHub::Standing.new(
        record: nil, rule: achievements_only, achievement_values: {},
        points_still_open: 0, points_due: 0, points_awaiting_marks: 0,
        sheets_awaiting_marks: 0, assignments_complete: true,
        uses_exam_eligibility: true
      )
      allow(built).to receive(:required_achievements).and_return([talk])

      content = render_standing(built)

      expect(content).to include(I18n.t("submission.hub.standing.not_recorded"))
      expect(content)
        .not_to include(I18n.t("submission.hub.standing.not_passed"))
    end

    it "says not passed for one that was graded and fell short" do
      built = standing(rule: achievements_only, achievements: [talk])

      expect(render_standing(built))
        .to include(I18n.t("submission.hub.standing.not_passed"))
    end

    # An achievement that carries a number says what was recorded, not just
    # that it was not enough.
    it "names the value recorded for one that carries a number" do
      built = standing(rule: achievements_only, achievements: [attendance],
                       values: { 2 => "67.3" })

      content = render_standing(built)

      expect(content).to include(
        I18n.t("submission.hub.standing.achievement_threshold",
               title: "Attendance Rate", threshold: "80", unit: "%").squish
      )
      expect(content).to include("67.3")
    end
  end

  # Red at most once per block, and only where nothing can change any more: one
  # loss is a fact, three is a scolding.
  describe "what is settled and what is still open" do
    let(:unreachable) { rule(:absolute, absolute: 90) }

    it "leaves everything grey while the points are still reachable" do
      built = standing(rule: unreachable, total: 60, still_open: 40,
                       achievements: [achievement], ungraded: [1])

      content = render_standing(built)

      expect(content).not_to include("req-lost")
    end

    it "marks the points once even full marks would not reach the threshold" do
      built = standing(rule: unreachable, total: 20, still_open: 16)

      content = render_standing(built)

      expect(content.scan("req-lost").size).to eq(1)
    end

    # The claim is "even everything still open would not be enough", and it
    # holds only while the list of sheets is closed: one more sheet lifts what
    # is reachable by its points and the threshold by half of them, so out of
    # reach turns back into reachable. The rest of the block is description and
    # stays; this one line is a judgement.
    it "passes no judgement while the lecture may still add sheets" do
      built = standing(rule: unreachable, total: 20, still_open: 16,
                       complete: false)

      content = render_standing(built)

      expect(content).not_to include("req-lost")
      expect(content)
        .not_to include(I18n.t("submission.hub.standing.what_this_means"))
      expect(content).to include("20")
    end

    # Reachability is a question about the end of term, so it is weighed
    # against what the term will hold. Against the points due so far this
    # reader would look fine and nothing would be said.
    it "weighs what is reachable against the whole term" do
      built = standing(rule: rule(:percentage, percentage: 50), total: 10,
                       still_open: 20, due: 36, max: 176)

      content = render_standing(built)

      expect(content).to include("req-lost")
      expect(content).to include(
        I18n.t("submission.hub.standing.out_of_reach", best: "30", needed: "88")
      )
    end

    it "marks a failed condition where the points are still open" do
      built = standing(rule: unreachable, total: 60, still_open: 40,
                       achievements: [achievement])

      content = render_standing(built)

      expect(content.scan("req-lost").size).to eq(1)
    end

    it "marks only one where two are settled against the reader" do
      built = standing(rule: unreachable, total: 20, still_open: 16,
                       achievements: [achievement])

      content = render_standing(built)

      expect(content.scan("req-lost").size).to eq(1)
    end
  end

  describe "what this means" do
    let(:unreachable) { rule(:absolute, absolute: 88) }

    it "spells out what is left once the points are out of reach" do
      built = standing(rule: unreachable, total: 32.5, still_open: 16,
                       achievements: [achievement])

      content = render_standing(built)

      expect(content)
        .to include(I18n.t("submission.hub.standing.what_this_means"))
      expect(content).to include(
        I18n.t("submission.hub.standing.out_of_reach", best: "48.5",
                                                       needed: "88")
      )
      expect(content).to include(
        I18n.t("submission.hub.standing.recorded_as_failed",
               names: "Blackboard Talk")
      )
    end

    # A standing that is merely open explains itself.
    it "says nothing while nothing is settled against the reader" do
      built = standing(rule: unreachable, total: 60, still_open: 40)

      expect(render_standing(built))
        .not_to include(I18n.t("submission.hub.standing.what_this_means"))
    end
  end
end
