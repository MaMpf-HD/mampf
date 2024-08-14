class AnnotationAbility
  include CanCan::Ability

  def initialize(user)
    can [:edit, :update, :destroy], Annotation do |annotation|
      annotation.user == user
    end

    can [:index, :new, :create, :update_annotations, :num_nearby_posted_mistake_annotations],
        Annotation
  end
end
