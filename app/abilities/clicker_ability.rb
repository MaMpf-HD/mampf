class ClickerAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:new, :create], Clicker do
      !user.generic?
    end

    can [:show, :get_votes_count], Clicker

    can [:edit, :open, :close, :set_alternatives], Clicker do |clicker, code|
      (user&.admin? || user == clicker.editor) || code == clicker.code
    end

    can [:associate_question, :remove_question, :destroy], Clicker do |clicker|
      clicker.editor == user
    end
  end
end
