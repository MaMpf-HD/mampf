# MainController
class MainController < ApplicationController
  before_action :check_for_consent
  authorize_resource class: false, only: :start
  layout "application_no_sidebar"

  def current_ability
    @current_ability ||= MainAbility.new(current_user)
  end

  def home
    cookies[:locale] = current_user.locale if user_signed_in?
    announcements
  end

  def error
    redirect_to :root, alert: I18n.t("controllers.no_page")
  end

  def news
    @announcements = Announcement.where(lecture: nil).order(:created_at)
                                 .reverse
  end

  def sponsors
  end

  def comments
    @media_comments = current_user.subscribed_media_with_latest_comments_not_by_creator
    @media_comments.select! do |m|
      (Reader.find_by(user: current_user, thread: m[:thread])
            &.updated_at || 1000.years.ago) < m[:latest_comment].created_at &&
        m[:medium].visible_for_user?(current_user)
    end
    @media_array = Kaminari.paginate_array(@media_comments)
                           .page(params[:page]).per(10)
  end

  def start
    @current_stuff = current_user.current_subscribed_lectures
    if @current_stuff.empty?
      @inactive_lectures = current_user.inactive_lectures.includes(:course,
                                                                   :term)
                                       .sort
    end
    announcements
    @talks = current_user.talks.includes(lecture: :term)
                         .select { |t| t.visible_for_user?(current_user) }
                         .sort_by do |t|
                           [-t.lecture.term.begin_date.jd,
                            t.position]
                         end
  end

  private

    def check_for_consent
      return unless user_signed_in?

      redirect_to consent_profile_path unless current_user.consents
    end

    def announcements
      @announcements = Announcement.where(on_main_page: true, lecture: nil)
                                   .pluck(:details)
                                   .join('<hr class="my-3" w-100>')
    end
end
