# Puts a student's newly published exam and talk results at the top of the
# lecture home, where the mail announcing them leads, until the student
# closes them; the participation row keeps showing them afterwards.
class NewResultsComponent < ViewComponent::Base
  def self.dom_id_for(participation)
    "new-result-#{participation.id}"
  end

  def initialize(lecture:, user:)
    super()
    @lecture = lecture
    @user = user
  end

  def render?
    results.any?
  end

  def results
    @results ||= Assessment::Participation.new_results_for(@user, @lecture)
                                          .map { |participation| ResultSummary.new(participation) }
  end

  def dom_id_for(result)
    self.class.dom_id_for(result.participation)
  end

  def headline(result)
    return t("registration.user_registration.participation.absent") if result.absent?
    return t("registration.user_registration.participation.exempt") if result.exempt?

    result.grade || t("registration.user_registration.participation.marked")
  end

  def grade_label?(result)
    !result.absent? && !result.exempt? && result.grade.present?
  end
end
