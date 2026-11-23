class AnnouncementAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    # site-wide announcements
    can [:index, :update], Announcement do
      user.admin?
    end

    can [:new, :create], Announcement do |announcement|
      user.admin? ||
        (announcement.lecture.present? && user.can_edit?(announcement.lecture))
    end
  end
end
