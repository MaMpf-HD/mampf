# ProfileController
class ProfileController < ApplicationController
  before_action :set_user
  before_action :set_basics, only: [:update]
  before_action :set_teachable, only: [:subscribe_teachable,
                                       :unsubscribe_teachable]

  def edit
    # ensure that users do not have a blank name and a locale
    @user.update(name: @user.name || @user.email.split('@').first,
                 locale: @user.locale || I18n.default_locale.to_s)
    unless @user.consents
      redirect_to consent_profile_path
      return
    end
    # destroy the notifications related to new lectures and courses
    current_user.notifications.where(notifiable_type: ['Lecture', 'Course'])
                .destroy_all
    render layout: 'application_no_sidebar'
  end

  def update
    check_passphrases
    return if @errors.present?
    if @user.update(lectures: @lectures, courses: @courses, name: @name,
                    subscription_type: @subscription_type,
                    email_for_medium: @email_for_medium,
                    email_for_teachable: @email_for_teachable,
                    email_for_announcement: @email_for_announcement,
                    email_for_news: @email_for_news,
                    locale: @locale,
                    edited_profile: true)
      # remove notifications that have become obsolete
      clean_up_notifications
      # add details about users's subscribed courses to CourseUserJoin
      add_details
      # update course and lecture cookies
      update_course_cookie
      update_lecture_cookie
      I18n.locale = @locale
      cookies[:locale] = @locale
      @user.touch
      redirect_to :root, notice: t('profile.success')
    else
      @errors = @user.errors
    end
  end

  # this is triggered after every sign in
  # if profile has never been edited user is redirected
  def check_for_consent
    if @user.consents && @user.edited_profile
      redirect_to :root
      return
    end
    return unless @user.consents
    redirect_to edit_profile_path,
                notice: t('profile.please_update')
  end

  # DSGVO consent action
  def add_consent
    @user.update(consents: true, consented_at: Time.now)
    redirect_to :root, notice: t('profile.consent')
  end

  def toggle_thread_subscription
    @thread = Commontator::Thread.find(params[:id])
    if @thread && @thread.can_subscribe?(@user)
      if params[:subscribe] == 'true'
        @thread.subscribe(@user)
      else
        @thread.unsubscribe(@user)
      end
      @result =  !!@thread.subscription_for(@user)
    end
  end

  def subscribe_teachable
    @success = false
    return if @teachable.is_a?(Lecture) && @teachable.passphrase.present? &&
                !@teachable.in?(current_user.lectures) &&
                @teachable.passphrase != @passphrase
    @success = current_user.subscribe_teachable!(@teachable)
  end

  def unsubscribe_teachable
    @success = current_user.unsubscribe_teachable!(@teachable)
    @none_left = case @parent
      when 'current_subscribed' then current_user.current_teachables.empty?
      when 'inactive' then current_user.inactive_lectures.empty?
    end
  end

  def show_accordion
    @collapse_id = params[:id]
    @teachables = case @collapse_id
      when 'collapseCurrentStuff' then current_user.current_teachables
      when 'collapseInactiveLectures' then current_user.inactive_lectures
                                                       .includes(:course, :term)
                                                       .sort
      when 'collapseAllCurrent' then Lecture.published.in_current_term
                                            .includes(:course, :term).sort
    end
  end

  private

  def set_user
    @user = current_user
  end

  def set_basics
    @subscription_type = params[:user][:subscription_type].to_i
    @name = params[:user][:name]
    @email_for_medium = params[:user][:email_for_medium] == '1'
    @email_for_announcement = params[:user][:email_for_announcement] == '1'
    @email_for_teachable = params[:user][:email_for_teachable] == '1'
    @email_for_news = params[:user][:email_for_news] == '1'
    @courses = Course.where(id: course_ids)
    @lectures = Lecture.where(id: lecture_ids)
    @locale = params[:user][:locale]
  end

  def set_teachable
    return unless teachable_params[:type].in?(['Lecture', 'Course'])
    @teachable = teachable_params[:type]
                   .constantize.find_by_id(teachable_params[:id])
    @passphrase = teachable_params[:passphrase]
    @parent = teachable_params[:parent]
    redirect_to start_path unless @teachable
  end

  def teachable_params
    params.require(:teachable).permit(:type, :id, :passphrase, :parent)
  end

  # extracts all course ids from user params
  def course_ids
    filter_by('course')
  end

  # extracts all lecture ids (primary and secondary) from user params
  def lecture_ids
    primary + secondary
  end

  # extracts primary lecture from user params
  def primary
    params[:user].keys.select { |k| k.start_with?('primary_lecture-') }
                 .reject { |c| params[:user][c] == '0' }
                 .map { |c| params[:user][c] }.map(&:to_i)
  end

  # extracts secondary lectures from user params
  def secondary
    filter_by('lecture') - primary
  end

  # extracts selected (secondary) lectures/courses (given as type)
  # from user params
  def filter_by(type)
    params[:user].keys.select { |k| k.start_with?(type + '-') }
                 .select { |c| params[:user][c] == '1' }
                 .map { |c| c.remove(type + '-').to_i }
  end

  # for each subscribed course, add details about current user's extras
  def add_details
    @courses.each do |c|
      details = CourseUserJoin.where(user: @user, course: c).first
      details.update(c.extras(params[:user]))
    end
  end

  def clean_up_notifications
    # delete all of the user's notifications if he does not want them
    # remove all notification related not related to subscribed courses
    # or lectures
    subscribed_teachables = @courses + @lectures
    irrelevant_notifications = @user.notifications.select do |n|
      n.teachable.present? && !n.teachable.in?(subscribed_teachables)
    end
    Notification.where(id: irrelevant_notifications.map(&:id)).delete_all
  end

  # if user unsubscribed the course to which the course cookie refers to,
  # update the course cookie to contain the first of the user's courses
  def update_course_cookie
    return if @user.courses.map(&:id).include?(cookies[:current_course].to_i)
    cookies[:current_course] = @courses&.first&.id
  end

  # if user unsubscribed the lecture the current lecture cookie refers to,
  # update the lecture cookie to contain the course's primary lecture id
  def update_lecture_cookie
    @course = Course.find_by_id(cookies[:current_course])
    @current_lecture = Lecture.find_by_id(cookies[:current_lecture])
    unless @current_lecture.in?(@user.lectures)
      cookies[:current_lecture] = @course&.primary_lecture(@user)&.id
    end
  end

  # stop the update if any of passphrases for newly subscribed primary/secondary
  # lectures is incorrect
  def check_passphrases
    @errors = {}
    restricted_primaries = Lecture.where(id: primary)
                                  .select do |l|
                                    l.in?(l.course
                                           .to_be_authorized_lectures(current_user))
                                  end
    restricted_primaries.each do |l|
      given_passphrase = params[:user]['pass_primary_' + l.course.id.to_s]
      unless given_passphrase == l.passphrase
        @errors[:primary_pass] ||= []
        @errors[:primary_pass].push l.course.id
      end
    end
    restricted_secondaries = Lecture.where(id: secondary)
                                    .select do |l|
                                      l.in?(l.course
                                             .to_be_authorized_lectures(current_user))
                                    end
    restricted_secondaries.each do |l|
      given_passphrase = params[:user]['pass_lecture-' + l.id.to_s]
      unless given_passphrase == l.passphrase
        @errors[:secondary_pass] ||= []
        @errors[:secondary_pass].push l.id
      end
    end
  end
end
