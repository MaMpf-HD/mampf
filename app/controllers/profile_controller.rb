# ProfileController
class ProfileController < ApplicationController
  before_action :set_user

  def edit
    redirect_to consent_profile_path unless @user.consents
  end

  def update
    set_basics
    if @user.update(lectures: @lectures, courses: @courses,
                    subscription_type: @subscription_type, edited_profile: true)
      add_details
      cookies[:current_lecture] = @lectures.first.id if @lectures.present?
      redirect_to :root, notice: 'Profil erfolgreich geupdatet.'
    else
      @no_course_error = @user.errors
    end
  end

  def check_for_consent
    if @user.consents && @user.edited_profile
      redirect_to :root
      return
    end
    if @user.consents
      redirect_to edit_profile_path,
                  notice: 'Bitte nimm Dir ein paar Minuten Zeit, um Dein ' \
                          'Profil zu bearbeiten.'
    end
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

  def set_basics
    @subscription_type = params[:user][:subscription_type].to_i
    @courses = Course.where(id: course_ids)
    @lectures = Lecture.where(id: lecture_ids)
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

  def add_details
    @problem_courses = []
    @courses.each do |c|
      details = CourseUserJoin.where(user: @user, course: c).first
      details.update(c.extras(params[:user]))
    end
  end
end
