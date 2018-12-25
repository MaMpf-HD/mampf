# NotificationsController
class NotificationsController < ApplicationController
  before_action :set_notification, only: [:destroy]
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

  def destroy_all
    current_user.notifications.each(&:destroy)
  end

  def destroy_lecture_notifications
    lecture = Lecture.find_by_id(params[:lecture_id])
    return unless lecture.present?
    current_user.active_announcements(lecture).each(&:destroy)
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