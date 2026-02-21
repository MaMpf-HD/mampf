class ExamParticipantsComponent < ViewComponent::Base
  def initialize(exam:)
    super()
    @exam = exam
  end

  def entries
    @entries ||= @exam.exam_rosters
                      .includes(:user)
                      .joins(:user)
                      .merge(User.order(:name))
  end
end
