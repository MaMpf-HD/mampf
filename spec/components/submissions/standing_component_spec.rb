require "rails_helper"

RSpec.describe(StandingComponent, type: :component) do
  # The design is written in English, and so are its numbers.
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  def record_defaults
    { total: 32.5, max: 176, pending: 16, percentage: 18.47, met: [],
      ungraded: [] }
  end

  def record(**overrides)
    attrs = record_defaults.merge(overrides)
    instance_double(StudentPerformance::Record,
                    points_total_materialized: attrs[:total],
                    points_max_materialized: attrs[:max],
                    points_max_pending_materialized: attrs[:pending],
                    percentage_materialized: attrs[:percentage],
                    achievements_met_ids: attrs[:met],
                    achievements_ungraded_ids: attrs[:ungraded])
  end

  def achievement(title: "Blackboard Talk", id: 1, value_type: :boolean,
                  threshold: nil)
    instance_double(Achievement, id: id, title: title, threshold: threshold,
                                 boolean?: value_type == :boolean,
                                 percentage?: value_type == :percentage)
  end

  def standing_defaults
    { rule: nil, achievements: [], values: {}, eligibility: true,
      still_open: 0 }
  end

  def standing(**overrides)
    attrs = standing_defaults.merge(overrides)
    record_options = overrides.except(*standing_defaults.keys)
    Assessment::SubmissionsHub::Standing.new(
      record: record(**record_options), rule: attrs[:rule],
      achievement_values: attrs[:values], points_still_open: attrs[:still_open],
      uses_exam_eligibility: attrs[:eligibility]
    ).tap do |built|
      allow(built).to receive(:required_achievements)
        .and_return(attrs[:achievements])
    end
  end

  def rule(mode, percentage: nil, absolute: nil)
    instance_double(StudentPerformance::Rule,
                    threshold_mode_percentage?: mode == :percentage,
                    min_percentage: percentage,
                    min_points_absolute: absolute,
                    required_points: nil)
  end

  def render_standing(built)
    render_inline(described_class.new(standing: built))
    rendered_content
  end

  describe "the points and the bar" do
    it "says what has been earned of what there is" do
      content = render_standing(standing)

      expect(content).to include("32.5")
      expect(content)
        .to include(I18n.t("submission.hub.standing.of_points", max: "176"))
    end

    it "fills the bar with the share earned" do
      content = render_standing(standing)

      expect(content).to include("width: 18.47%")
    end

    # A bar without a scale claims a ratio that does not exist.
    it "draws no bar where the lecture is worth no points" do
      content = render_standing(standing(max: 0))

      expect(content).not_to include("standing-bar")
      expect(content)
        .to include(I18n.t("submission.hub.standing.no_max"))
    end

    it "says so while nothing has been marked at all" do
      content = render_standing(standing(total: nil, percentage: nil))

      expect(content)
        .to include(I18n.t("submission.hub.standing.nothing_marked"))
    end

    # The pending points are a sentence, not a second number competing with the
    # first: a half-marked sheet shows its points in the list, counts nothing
    # towards the total, and sits here with its full worth.
    it "says how much is still being marked" do
      content = render_standing(standing)

      expect(content)
        .to include(I18n.t("submission.hub.standing.pending", points: "16"))
    end

    it "says nothing about pending points when none are" do
      content = render_standing(standing(pending: 0))

      expect(content)
        .not_to include(I18n.t("submission.hub.standing.pending", points: "0"))
    end
  end

  describe "a percentage rule" do
    let(:percentage_rule) do
      built = rule(:percentage, percentage: 50)
      allow(built).to receive(:required_points).and_return(88)
      built
    end

    it "names the threshold in the words the rule was written in" do
      content = render_standing(standing(rule: percentage_rule))

      expect(content).to include(
        I18n.t("submission.hub.standing.condition_percentage", percentage: "50")
      )
      expect(content).to include(
        I18n.t("submission.hub.standing.you_have_percent", percentage: "18.47")
      )
    end

    # The mark says what the rule says. `points_max_materialized` grows with
    # every sheet the lecture adds, so "88 needed" against a fixed mark is a
    # different number every week; the points go into the title instead.
    it "labels the mark with the rule, not with a number that moves" do
      content = render_standing(standing(rule: percentage_rule))

      expect(content).to include("left: 50.0%")
      expect(content).to include(
        I18n.t("submission.hub.standing.mark_percentage", percentage: "50")
      )
      expect(content).to include(
        "title=\"#{I18n.t("submission.hub.standing.needed", points: "88")}\""
      )
    end
  end

  describe "an absolute rule" do
    let(:absolute_rule) do
      built = rule(:absolute, absolute: 90)
      allow(built).to receive(:required_points).and_return(90)
      built
    end

    # An absolute rule keeps its number on the mark: there the number is the rule.
    it "labels the mark with the points, and names the threshold in points" do
      content = render_standing(standing(rule: absolute_rule, total: 104.5))

      expect(content)
        .to include(I18n.t("submission.hub.standing.needed", points: "90"))

      expect(content).to include(
        I18n.t("submission.hub.standing.condition_absolute", points: "90",
                                                             max: "176")
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
    let(:achievements_only) do
      built = rule(:none)
      allow(built).to receive(:required_points).and_return(nil)
      built
    end

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
    let(:unreachable) do
      built = rule(:absolute, absolute: 90)
      allow(built).to receive(:required_points).and_return(90)
      built
    end

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
    let(:unreachable) do
      built = rule(:absolute, absolute: 88)
      allow(built).to receive(:required_points).and_return(88)
      built
    end

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
