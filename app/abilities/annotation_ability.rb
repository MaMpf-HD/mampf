class AnnotationAbility
  include CanCan::Ability

  def initialize(user)
  	can [:edit, :update, :destroy], Annotation do |annotation|
  	  annotation.user == user
  	end
  	
  	can [:new, :create, :update_annotations, :near_mistake_annotations], Annotation
  end
  
end
