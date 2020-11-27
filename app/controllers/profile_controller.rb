# ProfileController
class ProfileController < ApplicationController
  before_action :set_user
  before_action :set_basics, only: [:update]
  before_action :set_lecture, only: [:subscribe_lecture, :unsubscribe_lecture,
                                     :star_lecture, :unstar_lecture]

  def edit
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
    if @user.update(lectures: @lectures,
                    name: @name,
                    name_in_tutorials: @name_in_tutorials,
                    subscription_type: @subscription_type,
                    locale: @locale)
      @user.update(email_params)
      # remove notifications that have become obsolete
      clean_up_notifications
      # update lecture cookie
      update_lecture_cookie
      I18n.locale = @locale
      cookies[:locale] = strict_cookie(@locale)
      @user.touch
      redirect_to :start, notice: t('profile.success')
    else
      @errors = @user.errors
    end
  end

  # this is triggered after every sign in
  # if profile has never been edited user is redirected
  def check_for_consent
    if @user.consents
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

  def subscribe_lecture
    @success = false
    if !@lecture.published? && !current_user.admin &&
      !@lecture.edited_by?(current_user)
      @unpublished = true
      return
    end
    return if @lecture.passphrase.present? &&
                !@lecture.in?(current_user.lectures) &&
                @lecture.passphrase != @passphrase
    @success = current_user.subscribe_lecture!(@lecture)
  end

  def unsubscribe_lecture
    @success = current_user.unsubscribe_lecture!(@lecture)
    @none_left = case @parent
      when 'current_subscribed' then current_user.current_subscribed_lectures
                                                 .empty?
      when 'inactive' then current_user.inactive_lectures.empty?
    end
  end

  def star_lecture
    return unless @lecture&.in?(current_user.lectures)
    if !@lecture.in?(current_user.favorite_lectures)
      current_user.favorite_lectures << @lecture
    end
    # as favorite lectures appear in the navbar which is cached e.g. in
    # the lecture show action, make sure the cache is invalidated by
    # touching the user
    current_user.touch
    @success = true
  end

  def unstar_lecture
    return unless @lecture
    current_user.favorite_lectures.delete(@lecture)
    current_user.touch
  end

  def show_accordion
    @collapse_id = params[:id]
    @lectures = case @collapse_id
      when 'collapseCurrentStuff' then current_user.current_subscribed_lectures
      when 'collapseInactiveLectures' then current_user.inactive_lectures
                                                       .includes(:course, :term)
                                                       .sort
      when 'collapseAllCurrent' then current_user.current_subscribable_lectures
    end
    @link = @collapse_id.remove('collapse').camelize(:lower) + 'Link'
  end

  private

  def set_user
    @user = current_user
  end

  def set_basics
    @subscription_type = params[:user][:subscription_type].to_i
    @name = params[:user][:name]
    @name_in_tutorials = params[:user][:name_in_tutorials]
    @lectures = Lecture.where(id: lecture_ids)
    @courses = Course.where(id: @lectures.pluck(:course_id).uniq)
    @locale = params[:user][:locale]
  end

  def email_params
    params.require(:user).permit(:email_for_medium, :email_for_announcement,
                                 :email_for_teachable, :email_for_news,
                                 :email_for_submission_upload,
                                 :email_for_submission_removal,
                                 :email_for_submission_join,
                                 :email_for_submission_leave,
                                 :email_for_correction_upload,
                                 :email_for_submission_decision)
  end

  def set_lecture
    @lecture = Lecture.find_by_id(lecture_params[:id])
    @passphrase = lecture_params[:passphrase]
    @parent = lecture_params[:parent]
    @current = !@parent.in?(['lectureSearch', 'inactive'])
    redirect_to start_path unless @lecture
  end

  def lecture_params
    params.require(:lecture).permit(:id, :passphrase, :parent)
  end

  # extracts all lecture ids from user params
  def lecture_ids
    params[:user][:lecture].select { |k, v| v == '1' }.keys.map(&:to_i)
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

  # if user unsubscribed the lecture the current lecture cookie refers to,
  # set the lectures cookie to nil
  def update_lecture_cookie
    unless @current_lecture.in?(@user.lectures)
      cookies[:current_lecture_id] = nil
    end
  end

  # stop the update if any of passphrases for newly subscribed
  # lectures is incorrect
  def check_passphrases
    @errors = {}
    restricted_lectures = Lecture.where(id: lecture_ids)
                                    .select do |l|
                                      l.in?(l.course
                                             .to_be_authorized_lectures(current_user))
                                    end
    restricted_lectures.each do |l|
      given_passphrase = params[:user][:pass_lecture][l.id.to_s]
      unless given_passphrase == l.passphrase
        @errors[:passphrase] ||= []
        @errors[:passphrase].push l.id
      end
    end
  end
end
