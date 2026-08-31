# The exam-admission block: what the reader has, what the lecture asks, and one
# line per condition in the words the rule was written in. Grey, unframed - it
# is the ground the action card stands on, not a second card.
#
# It is a second place on the page, which is why the actions that move a
# submission answer with a Turbo Stream rather than a frame: handing in makes a
# sheet count as "still being marked", and that number lives here.
class StandingComponent < ViewComponent::Base
  include ActiveSupport::NumberHelper

  # Named here rather than spelled out at each end: a stream target that stops
  # matching updates nothing and reports nothing.
  TARGET = "exam_standing".freeze

  attr_reader :standing

  delegate :rule, :record, :points_total, :points_max, :points_pending,
           :percentage, :required_points, :reachable_points,
           :points_out_of_reach?, :required_achievements, to: :standing

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

  def points_line
    return t("submission.hub.standing.no_max") unless points_max&.positive?

    t("submission.hub.standing.of_points", max: number(points_max))
  end

  def total
    marked? ? number(points_total) : "—"
  end

  # A bar needs a scale. With no maximum there is no ratio to draw, and a bar
  # drawn anyway would claim one.
  def bar?
    points_max&.positive?
  end

  def earned_percentage
    return 0 unless bar?

    [(points_total.to_f / points_max * 100).round(2), 100].min
  end

  def mark_percentage
    return unless bar? && required_points

    [(required_points.to_f / points_max * 100).round(2), 100].min
  end

  def mark_label
    t("submission.hub.standing.needed", points: number(required_points))
  end

  def bar_reader_label
    unless mark_percentage
      return t("submission.hub.standing.bar_plain",
               percentage: earned_percentage)
    end

    t("submission.hub.standing.bar_with_mark", percentage: earned_percentage,
                                               required: mark_percentage)
  end

  def pending_line
    return t("submission.hub.standing.nothing_marked") unless marked?
    return if points_pending.nil? || !points_pending.positive?

    t("submission.hub.standing.pending", points: number(points_pending))
  end

  def conditions?
    standing.uses_exam_eligibility && rule.present?
  end

  def points_condition
    return unless rule && required_points

    if rule.threshold_mode_percentage?
      t("submission.hub.standing.condition_percentage",
        percentage: number(rule.min_percentage))
    else
      t("submission.hub.standing.condition_absolute",
        points: number(required_points), max: number(points_max))
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

  def achievement_standing(achievement)
    case standing.achievement_status(achievement)
    when :met then t("submission.hub.standing.passed")
    when :ungraded then t("submission.hub.standing.not_recorded")
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
        best: number(reachable_points), needed: number(required_points))
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
