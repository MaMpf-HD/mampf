# Says whether the students see their results yet and lets the lecturer
# publish or take them back. A seminar has one button for all its talks, so
# the control counts them and each row marks its own.
class ResultsReleaseComponent < ViewComponent::Base
  ID = "results-release".freeze

  delegate :gradebooks, :published, :to_publish, to: :@release

  def initialize(exam: nil, seminar: nil)
    super()
    @exam = exam
    @seminar = seminar
    @release = Assessment::ResultsRelease.new(exam: exam, seminar: seminar)
  end

  def render?
    exam? || gradebooks.any?
  end

  def exam?
    @exam.present?
  end

  def path
    return helpers.assessment_assessment_results_path(@exam.assessment) if exam?

    helpers.assessment_talk_results_path(lecture_id: @seminar.id)
  end

  def status
    return exam_status if exam?
    return t("assessment.results_release.unpublished") if published.empty?
    return t("assessment.results_release.all_published") if published.size == gradebooks.size

    t("assessment.results_release.partly_published", published: published.size,
                                                     total: gradebooks.size)
  end

  def status_tooltip
    if exam?
      return t("assessment.results_release.exam_published_detail") if published.any?

      return (t("assessment.results_release.nobody_has_result") if to_publish.empty?)
    end
    t("assessment.results_release.no_talk_complete") if published.empty? && to_publish.empty?
  end

  def publish_label
    return t("assessment.results_release.publish") if exam?

    t("assessment.results_release.publish_talks", count: to_publish.size)
  end

  def withdraw_label
    t("assessment.results_release.withdraw")
  end

  def publish_confirm
    [t("assessment.results_release.publish_confirm", count: @release.people_count),
     mail_sentence, *grade_warnings].join(" ")
  end

  def withdraw_confirm
    t("assessment.results_release.withdraw_confirm")
  end

  private

    def exam_status
      return t("assessment.results_release.unpublished") if published.empty?

      t("assessment.results_release.exam_published",
        time: l(published.first.results_published_at, format: :short))
    end

    # What the students would see and the lecturer might not mean: a grade
    # the applied scheme no longer gives, or points with no grade at all.
    def grade_warnings
      return [] unless exam?

      warnings = []
      differing = scheme_disagreements
      if differing.positive?
        warnings << t("assessment.results_release.grades_differ", count: differing)
      end
      ungraded = @exam.assessment.assessment_participations.reviewed
                      .where(grade_numeric: nil, grade_text: [nil, ""]).count
      warnings << t("assessment.results_release.ungraded", count: ungraded) if ungraded.positive?
      warnings
    end

    def scheme_disagreements
      scheme = @exam.assessment.grade_scheme
      return 0 unless scheme&.persisted?

      Assessment::GradeSchemeApplier.new(scheme).preview_all.count do |row|
        row[:current_grade] && row[:current_grade] != row[:proposed_grade]
      end
    end

    def mail_sentence
      mailed = @release.mail_count
      return t("assessment.results_release.no_mail") if mailed.zero?
      return t("assessment.results_release.mail") if mailed == @release.people_count

      t("assessment.results_release.some_mail", count: mailed)
    end
end
