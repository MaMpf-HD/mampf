# ProfileController
class ProfileController < ApplicationController
  authorize_resource class: false
  before_action :set_user
  before_action :set_basics, only: [:update]
  before_action :set_lecture, only: [:subscribe_lecture, :unsubscribe_lecture,
                                     :star_lecture, :unstar_lecture]
  # A pass phrase is shared by the whole lecture, so guessing it is throttled
  # as in Lectures::UnlocksController; #update counts only the saves that
  # check one (see #check_passphrases).
  PASSPHRASE_ATTEMPTS = 10
  rate_limit to: PASSPHRASE_ATTEMPTS, within: 1.minute, only: :subscribe_lecture,
             by: -> { current_user&.id || request.remote_ip },
             with: -> { head :too_many_requests }

  def current_ability
    @current_ability ||= ProfileAbility.new(current_user)
  end

  def edit
    unless @user.consents
      redirect_to consent_profile_path
      return
    end
    # destroy the notifications related to new lectures and courses
    current_user.notifications.where(notifiable_type: ["Lecture", "Course"])
                .destroy_all
    render layout: "application_no_sidebar"
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
      I18n.locale = @locale
      cookies[:locale] = @locale
      @user.touch
      redirect_to :start, notice: t("profile.success")
    else
      @errors = @user.errors
    end
  end

  # Asks users who have not consented yet to do so; everyone else is sent on.
  def check_for_consent
    redirect_to :root if @user.consents
  end

  # DSGVO consent action
  def add_consent
    @user.update(consents: true, consented_at: Time.zone.now)
    redirect_to :root, notice: t("profile.consent")
  end

  def toggle_thread_subscription
    @thread = Commontator::Thread.find(params[:id])
    return unless @thread&.can_subscribe?(@user)

    if params[:subscribe] == "true"
      @thread.subscribe(@user)
    else
      @thread.unsubscribe(@user)
    end
    @result = !!@thread.subscription_for(@user)
  end

  def subscribe_lecture
    @success = false
    if !@lecture.published? && !current_user.admin &&
       !@lecture.edited_by?(current_user)
      @unpublished = true
      return
    end
    # Roster members may bookmark without the passphrase: a roster seat is
    # a stronger credential than a shared passphrase (see User#unlock_lecture!).
    @success = current_user.unlock_lecture!(@lecture, passphrase: @passphrase)
  end

  def unsubscribe_lecture
    @success = current_user.unbookmark_lecture!(@lecture)
  end

  def star_lecture
    return unless @lecture&.in?(current_user.lectures)

    current_user.favorite_lectures << @lecture unless @lecture.in?(current_user.favorite_lectures)
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

  # Firefox scrolls a newly-opened accordion fold out of view (see
  # show_accordion.coffee); other browsers do not need this.
  def show_accordion
    @collapse_id = params[:id]
    redirect_to :root and return if @collapse_id.blank?

    @link = "#{@collapse_id.remove("collapse").camelize(:lower)}Link"
  end

  def request_data
    MathiMailer.data_provide_email(current_user).deliver_later
  end

  private

    def set_user
      @user = current_user
    end

    def set_basics
      @subscription_type = params[:user][:subscription_type].to_i
      @name = params[:user][:name]
      @name_in_tutorials = params[:user].fetch(:name_in_tutorials, @user.name_in_tutorials)
      @lectures = Lecture.where(id: lecture_ids)
      @courses = Course.where(id: @lectures.pluck(:course_id).uniq)
      @locale = params[:user][:locale]
    end

    def email_params
      params.expect(user: [:email_for_medium, :email_for_announcement,
                           :email_for_teachable, :email_for_news,
                           :email_for_submission_upload,
                           :email_for_submission_removal,
                           :email_for_submission_join,
                           :email_for_submission_leave,
                           :email_for_correction_upload,
                           :email_for_submission_decision])
    end

    def set_lecture
      @lecture = Lecture.find_by(id: lecture_params[:id])
      @passphrase = lecture_params[:passphrase]
      @parent = lecture_params[:parent]
      @current = !@parent.in?(["lectureSearch", "inactive",
                               "next_term_subscribed", "next_term_registered"])
      redirect_to start_path unless @lecture
    end

    def lecture_params
      params.expect(lecture: [:id, :passphrase, :parent])
    end

    # extracts all lecture ids from user params
    def lecture_ids
      return [] if params[:user][:lecture].blank?

      params[:user][:lecture].select { |_k, v| v["subscribed"] == "1" }.keys.map(&:to_i)
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

    # stop the update if any of passphrases for newly subscribed
    # lectures is incorrect
    # Every lecture the save would newly bookmark goes through the rule of
    # User#unlock_lecture!, before anything is saved, so a refused one leaves
    # the whole profile unchanged.
    def check_passphrases
      @errors = {}
      bookmarked = current_user.lecture_bookmarks.pluck(:lecture_id)
      new_lectures = Lecture.where(id: lecture_ids - bookmarked).to_a
      return if new_lectures.empty?

      refused = if new_lectures.any?(&:restricted?) && passphrase_attempts_exhausted?
        new_lectures
      else
        new_lectures.reject do |lecture|
          current_user.may_unlock_lecture?(lecture, passphrase: passphrase_for(lecture))
        end
      end
      @errors[:passphrase] = refused.map(&:id) if refused.any?
    end

    def passphrase_for(lecture)
      params.dig(:user, :lecture, lecture.id.to_s, :passphrase)
    end

    def passphrase_attempts_exhausted?
      key = "profile-passphrase-attempts/#{current_user.id}"
      Rails.cache.increment(key, 1, expires_in: 1.minute).to_i > PASSPHRASE_ATTEMPTS
    end
end
