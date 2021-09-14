class ClickerAbility
  include CanCan::Ability

  def initialize(user)
    can [:new, :create] do
      !user.generic?
    end

    can [:edit, :open, :close, :set_alternatives, :get_votes_count]

    can [:associate_question, :remove_question, :destroy], Clicker do |clicker|
      clicker.editor == user
    end
  end
end
