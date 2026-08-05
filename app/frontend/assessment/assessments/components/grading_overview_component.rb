# Provides an overview of the grading status for a given assessment and lecture.
# Calculates the number of expected submissions, how many have been submitted,
# how many are missing, and provides information about the deadline.
class GradingOverviewComponent < ViewComponent::Base
  TutorialStat = Struct.new(:tutorial, :total, :submitted, keyword_init: true) do
    def name
      tutorial.title
    end

    def missing
      total - submitted
    end

    def progress_bar_color
      GradingOverviewComponent.progress_bar_color(submitted, total)
    end

    def progress_percentage
      GradingOverviewComponent.progress_percentage(submitted, total)
    end
  end

  # The same two rules apply to the course as a whole and to each tutorial.
  def self.progress_bar_color(done, expected)
    expected.positive? && done >= expected ? :success : :secondary
  end

  def self.progress_percentage(done, expected)
    return 0 if expected.zero?

    (done.to_f / expected * 100).round
  end

  def initialize(assessment:, lecture:)
    super()
    @assessment = assessment
    @lecture = lecture
  end

  attr_reader :assessment, :lecture

  def requires_submission?
    assessment.requires_submission
  end

  def deadline
    @deadline ||= assessment.assessable&.deadline
  end

  def closed?
    deadline.present? && deadline < Time.current
  end

  def missing_label
    if closed?
      I18n.t("assessment.grading_overview.not_submitted")
    else
      I18n.t("assessment.grading_overview.missing")
    end
  end

  DeadlineStatus = Struct.new(:phase, :icon, :color, keyword_init: true)

  DEADLINE_STATUSES = {
    urgent: DeadlineStatus.new(phase: :urgent, icon: "bi-exclamation-triangle",
                               color: "text-warning"),
    open: DeadlineStatus.new(phase: :open, icon: "bi-hourglass-split",
                             color: "text-muted"),
    just_closed: DeadlineStatus.new(phase: :just_closed, icon: "bi-inbox",
                                    color: "text-muted"),
    grading: DeadlineStatus.new(phase: :grading, icon: "bi-check-circle",
                                color: "text-success")
  }.freeze

  def deadline_status
    return nil unless deadline

    DEADLINE_STATUSES.fetch(deadline_phase)
  end

  def progress_bar_color
    self.class.progress_bar_color(submitted_count, total_expected)
  end

  def deadline_phase
    now = Time.current
    return (deadline - now) < 24.hours ? :urgent : :open if deadline > now

    (now - deadline) < 24.hours ? :just_closed : :grading
  end

  def total_expected
    @total_expected ||= roster_memberships.count
  end

  def submitted_count
    @submitted_count ||= participations.submitted.count
  end

  def missing_count
    total_expected - submitted_count
  end

  def progress_percentage
    self.class.progress_percentage(submitted_count, total_expected)
  end

  def tutorial_stats
    @tutorial_stats ||= build_tutorial_stats
  end

  private

    def participations
      @participations ||= assessment.assessment_participations
    end

    def roster_memberships
      @roster_memberships ||= TutorialMembership.where(tutorial_id: lecture.tutorial_ids)
    end

    def build_tutorial_stats
      stats = []

      membership_counts = roster_memberships.group(:tutorial_id).count
      submission_counts =
        participations
        .where.not(tutorial_id: nil)
        .where.not(submitted_at: nil)
        .group(:tutorial_id)
        .count

      lecture.tutorials.includes(:tutors).order(:title).each do |tutorial|
        total = membership_counts[tutorial.id] || 0
        next if total.zero?

        stats << TutorialStat.new(
          tutorial: tutorial,
          total: total,
          submitted: submission_counts[tutorial.id] || 0
        )
      end

      stats
    end
end
