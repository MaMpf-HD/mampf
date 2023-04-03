class SessionsController < Devise::SessionsController

  def initialize
    @announcements = Announcement
      .where(on_main_page: true, lecture: nil)
      .pluck(:details)
      .join
    super
  end

  # remove devise's flash message for succesful sign_in
  def create
    super
    flash.clear
  end
end