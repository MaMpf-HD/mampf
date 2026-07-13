class GradeTableComponent < ViewComponent::Base
  include ActionView::Helpers::DateHelper

  def initialize(assessment:)
    super()
    @assessment = assessment
  end

  attr_reader :assessment

  def displayed_participations
    @displayed_participations ||= assessment.assessment_participations
                                            .joins(:user)
                                            .includes(:user, :tutorial, :grader)
                                            .where(status: [:pending, :reviewed, :absent, :exempt])
                                            .order("users.name")
  end

  def any_displayed?
    displayed_participations.any?
  end

  def show_grader_column?
    displayed_participations.pluck(:grader_id).compact.uniq.size > 1
  end
end
