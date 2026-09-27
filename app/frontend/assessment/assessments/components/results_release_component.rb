# Says whether the students see their results yet and lets the lecturer
# publish or take them back: an exam's in the head of its grading card, a
# seminar's talks beside their table's summary, where one button serves every
# talk that is fully graded and each row marks the talks already published.
class ResultsReleaseComponent < ViewComponent::Base
  ID = "results-release".freeze

  def initialize(exam: nil, seminar: nil)
    super()
    @exam = exam
    @seminar = seminar
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

  # The gradebooks the button publishes: the exam's once somebody has a
  # result, a talk's once all its speakers have one.
  def to_publish
    @to_publish ||= if exam?
      assessment = @exam.assessment
      ready = assessment.assessment_participations.with_result.exists?
      assessment.results_published? || !ready ? [] : [assessment]
    else
      Assessment::Assessment.complete_talk_gradebooks(@seminar).reject(&:results_published?)
    end
  end

  def published
    @published ||= gradebooks.select(&:results_published?)
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
    count = Assessment::Participation.with_result.where(assessment: to_publish).count
    [t("assessment.results_release.publish_confirm", count: count),
     t("assessment.results_release.#{mails? ? "mail" : "no_mail"}"),
     *grade_warnings].join(" ")
  end

  def withdraw_confirm
    t("assessment.results_release.withdraw_confirm")
  end

  private

    def gradebooks
      @gradebooks ||= if exam?
        [@exam.assessment]
      else
        Assessment::Assessment.where(assessable: @seminar.talks).includes(:assessable).to_a
      end
    end

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

    # Only the first publication mails; see Assessment#publish_results!.
    def mails?
      to_publish.any? { |gradebook| gradebook.results_notified_at.nil? }
    end
end
