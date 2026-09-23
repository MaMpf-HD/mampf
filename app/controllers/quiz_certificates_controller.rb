# QuizCertificatesController
class QuizCertificatesController < ApplicationController
  before_action :set_certificate, only: :claim
  before_action :check_if_claimed, only: :claim
  before_action :set_lecture, only: :validate
  authorize_resource except: :validate

  def current_ability
    @current_ability ||= QuizCertificateAbility.new(current_user)
  end

  def claim
    @certificate.update(user: current_user)
  end

  def validate
    authorize! :validate, QuizCertificate.new
    code = certificate_params[:code]
    @certificate = QuizCertificate.find_by(code: code)
  end

  private

    def set_certificate
      @certificate = QuizCertificate.find_by(id: params[:id])
      return if @certificate.present?

      redirect_to :root, alert: I18n.t("controllers.no_certificate")
    end

    def check_if_claimed
      return unless @certificate.user

      redirect_to :root,
                  alert: I18n.t("controllers.certificate_already_claimed")
    end

    def certificate_params
      params.permit(:code, :lecture_id)
    end

    def set_lecture
      @lecture = Lecture.find_by(id: certificate_params[:lecture_id])
    end
end
