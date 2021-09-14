class AnnouncementAbility
  include CanCan::Ability

  def initialize(user)
    can [:index, :propagate, :expel], Announcement do
      user.admin?
    end

    can :new, Announcement do
      !user.generic?
    end

    can :create, Announcement do |announcement|
      user.admin? ||
      (announcement.lecture.present? && user.can_edit?(announcement.lecture))
    end
  end
end