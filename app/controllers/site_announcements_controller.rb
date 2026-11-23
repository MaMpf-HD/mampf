# Site-wide announcements: admins publish them as a banner above the navbar
# and switch that banner on or off. They belong to no lecture and notify
# nobody (see AnnouncementsController for lecture announcements).
class SiteAnnouncementsController < ApplicationController
  layout -> { turbo_frame_request? ? "turbo_frame" : "administration" }

  def current_ability
    @current_ability ||= SiteAnnouncementAbility.new(current_user)
  end

  def index
    authorize! :index, Announcement.new
    @pagy, @announcements = pagy(Announcement.site_wide.order(created_at: :desc),
                                 limit: 10)
  end

  def new
    @announcement = Announcement.new
    authorize! :new, @announcement
    redirect_to site_announcements_path unless turbo_frame_request?
  end

  # Publishing puts the announcement up as the banner right away.
  def create
    @announcement = Announcement.new(params.expect(announcement: [:details]))
    @announcement.announcer = current_user
    @announcement.banner_active = true
    authorize! :create, @announcement
    unless @announcement.save
      render :new, status: :unprocessable_content
      return
    end

    render turbo_stream: [
      turbo_stream.update("new_site_announcement", ""),
      turbo_stream.remove("no-site-announcements"),
      turbo_stream.prepend("site_announcements",
                           partial: "site_announcements/row",
                           locals: { announcement: @announcement }),
      banner_stream
    ]
  end

  # Switches the banner of an announcement on or off.
  def update
    @announcement = Announcement.find(params[:id])
    authorize! :update, @announcement
    @announcement.update(params.expect(announcement: [:banner_active]))
    render turbo_stream: [
      turbo_stream.replace(@announcement,
                           partial: "site_announcements/row",
                           locals: { announcement: @announcement }),
      banner_stream
    ]
  end

  private

    def banner_stream
      turbo_stream.replace("site-announcement-banner",
                           partial: "shared/announcement_banner")
    end
end
