# The exam-admission block: what the reader has, what the lecture asks, and one
# line per condition in the words the rule was written in. Grey, unframed - it
# is the ground the action card stands on, not a second card.
#
# It is a second place on the page, which is why the actions that move a
# submission answer with a Turbo Stream rather than a frame: what it says is
# read from the same sheets the card is, and the two must not drift apart.
class StandingComponent < ViewComponent::Base
  include ActiveSupport::NumberHelper

  # Named here rather than spelled out at each end: a stream target that stops
  # matching updates nothing and reports nothing.
  TARGET = "exam_standing".freeze

  attr_reader :standing

  delegate :rule, :record, :points_total, :points_due, :points_awaiting_marks,
           :sheets_awaiting_marks, :percentage, :required_points_due,
           :required_points_at_end, :reachable_points, :points_out_of_reach?,
           :required_achievements, to: :standing

  def initialize(standing:)
    super()
    @standing = standing
  end

  def target
    TARGET
  end

  def marked?
    points_total.present?
  end

  # An absolute rule names a number rather than a share, and the whole block
  # reads differently for it: its own target is the base, and the bar's end is
  # the threshold.
  def absolute?
    rule&.threshold_mode_absolute? && rule.min_points_absolute.to_f.positive?
  end

  # The base has to be said aloud. "34 of 36" on its own reads as a term worth
  # 36 points, when what it means is the two sheets that have come back.
  def points_line
    if absolute?
      return t("submission.hub.standing.of_needed",
               max: number(rule.min_points_absolute))
    end
    return t("submission.hub.standing.no_max") unless points_due.to_f.positive?

    t("submission.hub.standing.of_due", max: number(points_due))
  end

  def total
    marked? ? number(points_total) : "—"
  end

  # A bar needs a scale, and which scale is the rule's question. A percentage
  # rule weighs the reader against what is due, so bar and mark end up the same
  # quantity; an absolute rule weighs them against the number it names. Either
  # way a full bar means the condition is met.
  def bar_max
    absolute? ? rule.min_points_absolute : points_due
  end

  def bar?
    bar_max.to_f.positive?
  end

  def earned_percentage
    return 0 unless bar?

    [(points_total.to_f / bar_max * 100).round(2), 100].min
  end

  # The rule's own number, unconverted: both sides of the bar are now shares of
  # the same thing. An absolute rule gets no mark - its threshold is where the
  # bar ends.
  def mark_percentage
    return unless bar? && rule&.threshold_mode_percentage?

    rule.min_percentage.to_f.round(2)
  end

  def mark_label
    t("submission.hub.standing.mark_percentage",
      percentage: number(rule.min_percentage))
  end

  # The points behind the mark, for anybody who can hover. Nothing hangs on it:
  # there is no hovering on a phone.
  def mark_title
    return unless mark_percentage

    t("submission.hub.standing.needed", points: number(required_points_due))
  end

  def bar_reader_label
    if absolute?
      return t("submission.hub.standing.bar_absolute",
               points: number(points_total),
               needed: number(rule.min_points_absolute))
    end
    unless mark_percentage
      return t("submission.hub.standing.bar_plain",
               percentage: earned_percentage)
    end

    t("submission.hub.standing.bar_with_mark", percentage: earned_percentage,
                                               required: number(mark_percentage))
  end

  # Both numbers, because one alone leaves the reader guessing where it sits:
  # "8 points are still being marked" says nothing about whether the 8 are in
  # the total already. Named against the points due, they are.
  def pending_line
    return t("submission.hub.standing.nothing_marked") unless marked?
    return unless points_awaiting_marks.to_f.positive?

    t("submission.hub.standing.awaiting_marks",
      count: sheets_awaiting_marks, points: number(points_awaiting_marks),
      max: number(points_due))
  end

  def conditions?
    standing.uses_exam_eligibility && rule.present?
  end

  # What the lecture asks, in its own words. The absolute one names its number
  # alone: putting it over the term's total would bring back the very figure
  # this block stopped measuring by.
  def points_condition
    return unless rule && required_points_at_end

    if rule.threshold_mode_percentage?
      t("submission.hub.standing.condition_percentage",
        percentage: number(rule.min_percentage))
    else
      t("submission.hub.standing.condition_absolute",
        points: number(required_points_at_end))
    end
  end

  def points_standing
    if rule.threshold_mode_percentage?
      return t("submission.hub.standing.you_have_percent",
               percentage: number(percentage || 0))
    end

    t("submission.hub.standing.you_have_points", points: total)
  end

  def achievement_label(achievement)
    return achievement.title if achievement.boolean?

    t("submission.hub.standing.achievement_threshold",
      title: achievement.title, threshold: number(achievement.threshold),
      unit: achievement.percentage? ? "%" : "")
      .squish
  end

  # `:unknown` is "there is no record for this reader at all" - a different thing
  # from a condition that was graded and fell short, and it must not be shown as
  # one.
  def achievement_standing(achievement)
    case standing.achievement_status(achievement)
    when :met then t("submission.hub.standing.passed")
    when :ungraded, :unknown then t("submission.hub.standing.not_recorded")
    else recorded_or_failed(achievement)
    end
  end

  # Red appears at most once, and only where nothing can change it any more: one
  # loss is a fact, three is a scolding. The points come first because they are
  # the condition a student can still work on.
  def lost
    @lost ||= points_out_of_reach? ? :points : failed_achievements.first
  end

  def points_class
    lost == :points ? "req-lost" : "req-settled"
  end

  def achievement_class(achievement)
    lost == achievement ? "req-lost" : "req-settled"
  end

  # Only where something is settled against the reader is there anything to
  # explain; a standing that is merely open explains itself.
  def explanation
    return unless lost

    parts = []
    parts << out_of_reach_sentence if points_out_of_reach?
    parts << failed_sentence if failed_achievements.any?
    parts << t("submission.hub.standing.ask_your_tutor")
    parts.join(" ")
  end

  private

    def failed_achievements
      required_achievements.select do |achievement|
        standing.achievement_status(achievement) == :not_met
      end
    end

    def out_of_reach_sentence
      t("submission.hub.standing.out_of_reach",
        best: number(reachable_points), needed: number(required_points_at_end))
    end

    def failed_sentence
      t("submission.hub.standing.recorded_as_failed",
        names: failed_achievements.map(&:title).to_sentence)
    end

    # An achievement that carries a number says what was recorded; one that is
    # simply done or not done says that.
    def recorded_or_failed(achievement)
      value = standing.achievement_value(achievement)
      return t("submission.hub.standing.not_passed") if achievement.boolean? ||
                                                        value.blank?

      t("submission.hub.standing.you_have_value", value: value,
                                                  unit: achievement.percentage? ? "%" : "")
        .squish
    end

    def number(value)
      number_to_rounded(value || 0, precision: 2,
                                    strip_insignificant_zeros: true)
    end
end
