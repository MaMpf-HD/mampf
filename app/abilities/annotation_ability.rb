class AnnotationAbility
  include CanCan::Ability

  def initialize(user)
  	can :create, Annotation
  end
  
end
