# NotificationsController
class NotificationsController < ApplicationController
  before_action :set_notification, only: [:destroy]
  before_action :set_locale
  authorize_resource

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
  end

  # destroy all lecture notifications of current user
  def destroy_lecture_notifications
    lecture = Lecture.find_by_id(params[:lecture_id])
    return unless lecture.present?
    Notification.delete(current_user.active_announcements(lecture).pluck(:id))
    render :destroy_all
  end

  # destroy all notififications of current user that do not belong
  # to any lecture
  def destroy_news_notifications
    Notification.delete(current_user.active_news.pluck(:id))
    render :destroy_all
  end

  private

  def set_notification
    @notification = Notification.find_by_id(params[:id])
    return if @notification.present?
    redirect_to :root, alert: 'Eine Benachrichtigung mit der angeforderten id' \
                              'existiert nicht.'
  end
end
