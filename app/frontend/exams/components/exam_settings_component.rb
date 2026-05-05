class ExamSettingsComponent < ViewComponent::Base
  def initialize(exam:)
    super()
    @exam = exam
  end

  attr_reader :exam

  def display_date
    exam.date ? helpers.l(exam.date, format: :long) : helpers.t("basics.not_specified")
  end

  def display_location
    exam.location.presence || helpers.t("basics.not_specified")
  end

  def display_capacity
    exam.capacity || helpers.t("basics.unlimited")
  end

  def show_back_button?
    exam.new_record?
  end

  def show_delete_button?
    !exam.new_record?
  end

  def form_url
    if exam.new_record?
      helpers.exams_path
    else
      helpers.exam_path(exam)
    end
  end

  def back_path
    helpers.exams_path(lecture_id: exam.lecture_id)
  end

  def heading
    return helpers.t("assessment.new_exam") if exam.new_record?

    exam.title
  end
end