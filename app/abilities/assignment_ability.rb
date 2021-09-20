class AssignmentAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :create, :edit, :update, :destroy, :cancel_edit,
         :cancel_new], Assignment do |assignment|
      assignment.lecture.present? && user.can_edit?(assignment.lecture)
    end
  end
end