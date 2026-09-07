class TalkGradingTableComponent < ViewComponent::Base
  def initialize(seminar:)
    super()
    @seminar = seminar
    @talks = seminar.talks.includes(:speakers, :assessment)
  end

  def grading_enabled?
    true
  end

  def gradable_talks
    @gradable_talks ||= @talks.select { |t| t.speakers.any? && t.assessment.present? }
  end

  def legacy_talks
    @legacy_talks ||= @talks.select { |t| t.speakers.any? && t.assessment.blank? }
  end

  def possible_statuses
    ["pending", "reviewed"]
  end

  delegate :init_participation, to: :"Assessment::TalkGraderService"

  def grade_form_url(talk, user)
    helpers.grade_talk_user_path(talk, user)
  end

  def refresh_form_url(talk, user)
    helpers.refresh_grade_talk_user_path(talk, user)
  end
end
