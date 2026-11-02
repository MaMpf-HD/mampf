class ProfileAbility
  include CanCan::Ability

  def initialize(_user)
    clear_aliased_actions

    can [:edit, :update, :check_for_consent, :add_consent,
         :toggle_thread_subscription, :subscribe_lecture, :unsubscribe_lecture,
         :pin_lecture, :unpin_lecture, :show_accordion, :request_data], :profile
  end
end
