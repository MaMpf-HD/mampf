# NotificationsController
class NotificationsController < ApplicationController
  before_action :set_notification, only: [:destroy]
  authorize_resource

  def index
    @notifications = current_user.notifications.order(:created_at)
                                 .reverse_order
  end

  def destroy
    @notification.destroy
  end

  def destroy_all
    current_user.notifications.each(&:destroy)
  end

  private

  def set_notification
    @notification = Notification.find_by_id(params[:id])
    return if @notification.present?
    redirect_to :root, alert: 'Eine Benachrichtigung mit der angeforderten id' \
                              'existiert nicht.'
  end
end