class TutorAppointmentAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:create, :destroy], TutorAppointment do |appointment|
      user.can_update_personell?(appointment.lecture)
    end
  end
end
