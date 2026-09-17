# Something a student has to have done besides collecting points — held a
# blackboard talk, handed in a project. It carries no points of its own; the
# tutor enters a value per student, and an eligibility rule can require it.
class Achievement < ApplicationRecord
  include Assessment::Assessable

  # What a tutor enters for an achievement that is simply done or not done.
  # Written by the marking view, read here — keep both ends on this constant.
  PASSED = "pass".freeze

  belongs_to :lecture

  has_many :rule_achievements,
           class_name: "StudentPerformance::RuleAchievement",
           dependent: :restrict_with_error

  enum :value_type, { boolean: 0, numeric: 1, percentage: 2 }

  validates :title, :value_type, presence: true
  validates :title, uniqueness: { scope: :lecture_id }
  validates :threshold,
            numericality: { greater_than: 0 },
            if: :numeric?
  validates :threshold,
            numericality: { greater_than_or_equal_to: 0,
                            less_than_or_equal_to: 100 },
            if: :percentage?
  validates :threshold, absence: true, if: :boolean?
  validate :value_type_fixed_by_values, if: -> { persisted? && value_type_changed? }

  after_create :setup_assessment
  before_destroy :check_destructibility, prepend: true

  after_commit :invalidate_performance_records,
               on: [:update, :destroy],
               if: :should_invalidate_performance_records?

  # A German keyboard writes 3,5 and means three and a half. Returns nil for
  # anything that is no number at all - "Infinity" and "NaN" included, which
  # BigDecimal reads and a threshold cannot judge - so callers can say so
  # rather than counting it as zero.
  def self.numeric_value(grade_text)
    number = BigDecimal(grade_text.to_s.strip.tr(",", "."))
    number if number.finite?
  rescue ArgumentError
    nil
  end

  # Short headings leave room for the achievement status icons.
  def short_title
    words = title.to_s.scan(/[[:alnum:]]+/)
    return words[0, 2].pluck(0).join.upcase if words.size >= 2
    return words.first[0, 2].upcase if words.any?

    title.to_s[0, 2].upcase
  end

  def destructible?
    destruction_blockers.empty?
  end

  # Named as Assignment names them, so the delete button asks any assessable
  # the same question. An entered value or an exemption is somebody's work,
  # and a rule that requires the achievement would lose a condition.
  def destruction_blockers
    blockers = []
    blockers << :has_values if values_entered? || exemptions_entered?
    blockers << :referenced_by_rules if rule_achievements.exists?
    blockers
  end

  def self.short_titles(achievements)
    achievements.group_by(&:short_title).each_with_object({}) do |(short, group), headings|
      if group.size == 1
        headings[group.first.id] = short
      else
        group.each_with_index { |achievement, i| headings[achievement.id] = "#{short}#{i + 1}" }
      end
    end
  end

  # Where somebody stands on the achievement, as the tables show it:
  # excused, no value yet, or the value's verdict.
  def status_of(participation)
    return :exempt if participation.exempt?
    return :unmarked if participation.grade_text.blank?

    met_by?(participation.grade_text) ? :met : :not_met
  end

  # The one place that decides whether an entered value clears this
  # achievement. The marking table and the performance computation both ask
  # here, so the two cannot answer differently.
  def met_by?(grade_text)
    value = grade_text.to_s.strip
    return false if value.blank?
    return value == PASSED if boolean?
    return false if threshold.nil?

    number = self.class.numeric_value(value)
    return refuse_unreadable(value) if number.nil?

    number >= threshold
  end

  private

    def check_destructibility
      throw(:abort) unless destructible?

      true
    end

    # The values read by the type: "pass" says nothing on a numeric
    # achievement, 12.5 nothing on a yes/no one. The threshold may still
    # move; the values keep their meaning under a new one. Checked under the
    # achievement's lock, which a value entry takes as well.
    def value_type_fixed_by_values
      errors.add(:value_type, :fixed_by_values) if values_entered?
    end

    def values_entered?
      return false unless assessment

      assessment.assessment_participations.where.not(grade_text: [nil, ""]).exists?
    end

    def exemptions_entered?
      return false unless assessment

      assessment.assessment_participations.exempt.exists?
    end

    # Said out loud: a wrong "not met" here costs a student their exam
    # admission, and there is nothing else to notice it by.
    def refuse_unreadable(value)
      Rails.logger.warn do
        "Achievement #{id}: cannot read #{value.inspect} as a number"
      end
      false
    end

    def threshold_or_type_changed?
      saved_change_to_threshold? || saved_change_to_value_type?
    end

    def should_invalidate_performance_records?
      destroyed? || threshold_or_type_changed?
    end

    def invalidate_performance_records
      StudentPerformance::ComputationService
        .new(lecture: lecture)
        .compute_and_upsert_all_records!
      touch_linked_rules
    end

    def touch_linked_rules
      rule_ids = rule_achievements.pluck(:rule_id)
      return if rule_ids.empty?

      StudentPerformance::Rule.where(id: rule_ids).touch_all
    end

    def setup_assessment
      ensure_assessment!(requires_points: false, requires_submission: false)
      seed_participations!
    end

    def seed_participations!
      return unless assessment

      user_ids = lecture.members.pluck(:id)
      assessment.seed_participations_from!(user_ids: user_ids)
    end
end
