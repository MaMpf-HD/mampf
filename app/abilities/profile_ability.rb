class ProfileAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:edit, :update, :check_for_consent, :add_consent,
         :toggle_thread_subscription, :subscribe_lecture, :unsubscribe_lecture,
         :star_lecture, :unstar_lecture, :show_accordion], :profile
  end
end