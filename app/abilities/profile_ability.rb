class ProfileAbility
  include CanCan::Ability

  def initialize(_user)
    clear_aliased_actions

    can [:edit, :update,
         :toggle_thread_subscription, :subscribe_lecture, :unsubscribe_lecture,
         :star_lecture, :unstar_lecture, :show_accordion, :request_data], :profile
  end
end
