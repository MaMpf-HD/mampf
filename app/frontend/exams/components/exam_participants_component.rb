class ExamParticipantsComponent < ViewComponent::Base
  def initialize(exam:)
    super()
    @exam = exam
  end

  def entries
    @entries ||= @exam.exam_roster_entries
                      .includes(:user)
                      .joins(:user)
                      .merge(User.by_last_name)
  end
end
