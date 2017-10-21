# ProfileController
class ProfileController < ApplicationController
  before_action :set_user

  def edit
  end

  def update
    @lecture_ids = user_params[:lecture_ids].map(&:to_i)
    subscription_type = user_params[:subscription_type].to_i
    lectures = Lecture.where(id: @lecture_ids)
    if lectures.empty?
      redirect_to :edit_profile,
                  alert: 'Eine Vorlesung musst Du mindestens abonnieren.'
      return
    end
    @user.update(lectures: lectures, subscription_type: subscription_type)
    cookies[:current_lecture] = lectures.first.id if lectures.present?
    redirect_to :root, notice: 'Profil erfolgreich geupdatet.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = current_user
  end

  # Never trust parameters from the scary internet,
  #  only allow the white list through.
  def user_params
    params.fetch(:user, {}).permit(:subscription_type, lecture_ids: [])
  end
end
