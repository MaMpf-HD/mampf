# QuizCertificatesController
class QuizCertificatesController < ApplicationController
  before_action :set_certificate, only: :claim
  before_action :check_if_claimed, only: :claim
  before_action :set_locale_by_quiz, only: :claim
  before_action :set_locale_by_lecture, only: :validate
  authorize_resource

  def claim
    @certificate.update(user: current_user)
  end

  def validate
    code = certificate_params[:code]
    @certificate = QuizCertificate.find_by_code(code)
  end

  private

  def set_certificate
    @certificate = QuizCertificate.find_by_id(params[:id])
    return if @certificate.present?
    redirect_to :root, alert: I18n.t('controllers.no_certificate')
  end

  def check_if_claimed
    return unless @certificate.user
    redirect_to :root, alert: I18n.t('controllers.certificate_already_claimed')
  end

  def certificate_params
    params.permit(:code, :lecture_id)
  end

  def set_locale_by_quiz
    return unless @certificate
    quiz_locale = @certificate.quiz.locale_with_inheritance
    I18n.locale = quiz_locale || current_user.locale ||
                    I18n.default_locale
  end

  def set_locale_by_lecture
    @lecture = Lecture.find_by_id(certificate_params[:lecture_id])
    I18n.locale = @lecture&.locale_with_inheritance || current_user.locale ||
                    I18n.default_locale
  end
end