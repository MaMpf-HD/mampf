# Says whether the students see their results yet and lets the lecturer
# publish or take them back: an exam's in its grading tab, a seminar's talks
# above their table, where one button serves every talk that is fully graded.
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
    if exam?
      return t("assessment.results_release.exam_published", time: published_time) if published.any?

      return t("assessment.results_release.exam_unpublished")
    end
    t("assessment.results_release.talks_status", published: published.size,
                                                 ready: to_publish.size)
  end

  def detail
    return exam_detail if exam?

    parts = [talk_titles(:published, published), talk_titles(:ready, to_publish)].compact
    return t("assessment.results_release.no_talk_complete") if parts.empty?

    parts.join(" · ")
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
     t("assessment.results_release.#{mails? ? "mail" : "no_mail"}")].join(" ")
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

    def published_time
      l(published.first.results_published_at, format: :short)
    end

    def exam_detail
      return t("assessment.results_release.exam_published_detail") if published.any?
      return t("assessment.results_release.nobody_has_result") if to_publish.empty?

      nil
    end

    def talk_titles(state, gradebooks)
      return if gradebooks.empty?

      t("assessment.results_release.talks_#{state}",
        titles: gradebooks.map { |gradebook| gradebook.assessable.title }.join(", "))
    end

    # Only the first publication mails; see Assessment#publish_results!.
    def mails?
      to_publish.any? { |gradebook| gradebook.results_notified_at.nil? }
    end
end
