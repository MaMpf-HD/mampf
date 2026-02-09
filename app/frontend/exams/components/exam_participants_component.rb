# Missing top-level docstring, please formulate one yourself 😁
class ExamParticipantsComponent < ViewComponent::Base
  def initialize(exam:)
    super()
    @exam = exam
    @lecture = exam.lecture
  end

  def entries
    @entries ||= @exam.exam_rosters
                      .includes(:user)
                      .joins(:user)
                      .merge(User.order(:name))
  end

  def performance_available?
    defined?(StudentPerformance::Record)
  rescue NameError
    false
  end

  def performance_records
    return {} unless performance_available?

    @performance_records ||=
      StudentPerformance::Record
      .where(lecture: @lecture, user_id: user_ids)
      .index_by(&:user_id)
  end

  def certification_available?
    defined?(StudentPerformance::Certification)
  rescue NameError
    false
  end

  def certifications
    return {} unless certification_available?

    @certifications ||=
      StudentPerformance::Certification
      .where(lecture: @lecture, user_id: user_ids)
      .index_by(&:user_id)
  end

  def performance_for(user)
    performance_records[user.id]
  end

  def certification_for(user)
    certifications[user.id]
  end

  def certification_badge(user)
    cert = certification_for(user)
    return nil unless cert

    case cert.status.to_sym
    when :passed
      { color: "success", icon: "bi-check-circle-fill",
        label: I18n.t("student_performance.status.passed") }
    when :failed
      { color: "danger", icon: "bi-x-circle-fill",
        label: I18n.t("student_performance.status.failed") }
    when :pending
      { color: "warning", icon: "bi-hourglass-split",
        label: I18n.t("student_performance.status.pending") }
    end
  end

  private

    def user_ids
      @user_ids ||= entries.map(&:user_id)
    end
end
