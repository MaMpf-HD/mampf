class NotificationAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :destroy_all, :destroy_lecture_notifications,
         :destroy_news_notifications], Notification

    can :destroy, Notification do |notification|
      notification.recipient == user
    end
  end
end