# QuizCertificatesController
class QuizCertificatesController < ApplicationController
  before_action :set_certificate, only: :claim
  before_action :check_if_claimed, only: :claim
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
    params.permit(:code)
  end
end