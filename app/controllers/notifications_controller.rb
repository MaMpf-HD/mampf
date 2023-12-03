# NotificationsController
class NotificationsController < ApplicationController
  before_action :set_notification, only: [:destroy]
  authorize_resource

  def current_ability
    @current_ability ||= NotificationAbility.new(current_user)
  end

  def index
    @notifications = current_user.notifications.order(:created_at)
                                 .reverse_order
    render layout: 'application_no_sidebar'
  end

  def destroy
    @notification.destroy
    # do not render anything
    head :ok
  end

  # destroy all notifications of the current user
  def destroy_all
    current_user.notifications.delete_all
    current_user.touch
  end

  # destroy all lecture notifications of current user
  def destroy_lecture_notifications
    lecture = Lecture.find_by_id(params[:lecture_id])
    return unless lecture.present?

    Notification.delete(current_user.active_notifications(lecture).pluck(:id))
    current_user.touch
    render :destroy_all
  end

  # destroy all notififications of current user that do not belong
  # to any lecture
  def destroy_news_notifications
    Notification.delete(current_user.active_news.pluck(:id))
    current_user.touch
    render :destroy_all
  end

  private

    def set_notification
      @notification = Notification.find_by_id(params[:id])
      return if @notification.present?

      redirect_to :root, alert: I18n.t('controllers.no_notification')
    end
end
