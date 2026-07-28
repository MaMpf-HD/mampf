class GradeTalkRowsPerTalkComponent < ViewComponent::Base
  include ActionView::Helpers::DateHelper

  def initialize(assessment:)
    super()
    @assessment = assessment
  end

  attr_reader :assessment

  def displayed_participations
    @displayed_participations ||= assessment.init_or_get_assessment_participations_for_talks
                                            .joins(:user)
                                            .includes(:user, :tutorial, :grader)
                                            .where(status: [:pending, :reviewed, :absent, :exempt])
                                            .order("users.name")
  end
end
