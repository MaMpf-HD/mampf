# LecturesController
class LecturesController < ApplicationController
  before_action :set_lecture, only: [:edit]
  authorize_resource
  before_action :check_for_consent

  def index
    lectures = current_user.edited_lectures_with_inheritance
    edited_lectures = Lecture.sort_by_date(lectures).to_a
    other_lectures = Lecture.sort_by_date(Lecture.all.to_a - lectures)
    @lectures = Kaminari.paginate_array(edited_lectures + other_lectures)
                        .page params[:page]
  end

  def edit
  end

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
