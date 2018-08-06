# ProfileController
class ProfileController < ApplicationController
  before_action :set_user

  def edit
    redirect_to consent_profile_path unless @user.consents
  end

  def update
    subscription_type = params[:user][:subscription_type].to_i
    courses = Course.where(id: course_ids)
    lectures = Lecture.where(id: lecture_ids)
    if @user.update(lectures: lectures, courses: courses,
                    subscription_type: subscription_type, edited_profile: true)
      courses.each do |c|
        details = CourseUserJoin.where(user: @user, course: c).first
        unless details.update(c.extras(params[:user]))
          @error = details.errors
          @course = c
          return
        end
      end
      cookies[:current_lecture] = lectures.first.id if lectures.present?
      redirect_to :root, notice: 'Profil erfolgreich geupdatet.'
      return
    else
      @error = @user.errors
    end
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

  def set_user
    @user = current_user
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
