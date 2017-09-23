class ProfileController < ApplicationController
  before_action :set_user

  def show
  end

  def edit
  end

  def update
    @lecture_ids = user_params[:lecture_ids].map(&:to_i)
    lectures = Lecture.where(id: @lecture_ids)
    @user.update(lectures: lectures)
    redirect_to profile_path, notice: 'Profile successfully updated'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = current_user
  end

  # Never trust parameters from the scary internet,
  #  only allow the white list through.
  def user_params
    params.fetch(:user, {}).permit(lecture_ids: [])
  end
end
