# ProfileController
class ProfileController < ApplicationController
  before_action :set_user

  def edit
    redirect_to consent_profile_path unless @user.consents
  end

  def update
    subscription_type = user_params[:subscription_type].to_i
    courses = Course.where(id: course_ids)
    lectures = Lecture.where(id: lecture_ids)
    if courses.empty? && Course.any?
      redirect_to :edit_profile,
                  alert: 'Ein Modul musst Du mindestens abonnieren.'
      return
    end
    @user.update(lectures: lectures, courses: courses,
                 subscription_type: subscription_type)
    cookies[:current_lecture] = lectures.first.id if lectures.present?
    redirect_to :root, notice: 'Profil erfolgreich geupdatet.'
  end

  def check_for_consent
    redirect_to :root if @user.consents
  end

  def add_consent
    @user.update(consents: true, consented_at: Time.now)
    redirect_to :root, notice: 'Einwilligung zur Speicherung und Verarbeitung'\
                                'von Daten wurde erklärt.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = current_user
  end

  # Never trust parameters from the scary internet,
  #  only allow the white list through.
  def user_params
    params[:user]
  #  params.fetch(:user, {}).permit(:subscription_type, lecture_ids: [])
  end

  def course_ids
    params[:user].keys.select { |k| k.start_with?('course-') }
                 .select { |c| params[:user][c] == '1' }
                 .map { |c| c.remove('course-').to_i }
  end

  def lecture_ids
    params[:user].keys.select { |k| k.start_with?('lecture-') }
                 .select { |c| params[:user][c] == '1' }
                 .map { |c| c.remove('lecture-').to_i }
  end
end
