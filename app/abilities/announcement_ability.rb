class AnnouncementAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    # lecture announcements; site-wide ones go via SiteAnnouncementAbility
    can [:new, :create], Announcement do |announcement|
      announcement.lecture.present? && user.can_edit?(announcement.lecture)
    end
  end
end
