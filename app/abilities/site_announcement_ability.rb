class SiteAnnouncementAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    # site-wide announcements (no lecture) are an admin-only concern
    can [:index, :new, :create, :update], Announcement do |announcement|
      user.admin? && announcement.lecture.nil?
    end
  end
end
