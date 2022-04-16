class QuizCertificateAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can :claim, QuizCertificate

    can :validate, QuizCertificate do
      user.tutor? || !user.generic?
    end
  end
end