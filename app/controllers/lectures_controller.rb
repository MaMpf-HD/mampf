# LecturesController
class LecturesController < ApplicationController
  before_action :set_lecture, only: [:show]
  authorize_resource
  before_action :check_for_consent

  private

  def set_lecture
    @lecture = Lecture.find_by_id(params[:id])
    return if @lecture.present?
    redirect_to :root, alert: 'Eine Vorlesung mit der angeforderten id ' \
                              'existiert nicht.'
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end
end
