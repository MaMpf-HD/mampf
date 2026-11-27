class SiteAnnouncementAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:index, :new, :create, :update], Announcement do |announcement|
      user.admin? && announcement.lecture.nil?
    end
  end
end
