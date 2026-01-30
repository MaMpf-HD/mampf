class GradingOverviewComponent < ViewComponent::Base
  def initialize(assessment:, lecture:)
    super()
    @assessment = assessment
    @lecture = lecture
  end

  attr_reader :assessment, :lecture

  def requires_submission?
    assessment.requires_submission
  end

  def total_expected
    @total_expected ||= roster_memberships.count
  end

  def submitted_count
    @submitted_count ||= participations.where(status: [:submitted, :graded]).count
  end

  def graded_count
    @graded_count ||= participations.where(status: :graded).count
  end

  def missing_count
    total_expected - submitted_count
  end

  def progress_percentage
    return 0 if total_expected.zero?

    (submitted_count.to_f / total_expected * 100).round
  end

  def tutorial_stats
    @tutorial_stats ||= build_tutorial_stats
  end

  def has_tutorials?
    lecture.tutorials.any?
  end

  private

    def participations
      @participations ||= assessment.assessment_participations
    end

    def roster_memberships
      @roster_memberships ||= TutorialMembership.where(
        tutorial_id: lecture.tutorial_ids
      )
    end

    def build_tutorial_stats
      stats = []

      membership_counts = roster_memberships.group(:tutorial_id).count
      participation_data = participations
                           .where.not(tutorial_id: nil)
                           .group(:tutorial_id, :status)
                           .count

      lecture.tutorials.includes(:tutors).order(:title).each do |tutorial|
        total = membership_counts[tutorial.id] || 0
        next if total.zero?

        submitted = count_statuses(participation_data, tutorial.id, [:submitted, :graded])

        stats << TutorialStat.new(
          tutorial: tutorial,
          total: total,
          submitted: submitted
        )
      end

      stats
    end

    def count_statuses(grouped_data, tutorial_id, statuses)
      statuses.sum do |status|
        grouped_data[[tutorial_id, status.to_s]] || 0
      end
    end

    TutorialStat = Struct.new(:tutorial, :total, :submitted, keyword_init: true) do
      def name
        tutorial&.title || I18n.t("assessment.grading_overview.unassigned")
      end

      def missing
        total - submitted
      end

      def progress_percentage
        return 0 if total.zero?

        (submitted.to_f / total * 100).round
      end
    end
end
