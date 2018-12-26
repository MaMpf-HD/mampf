# AnnouncementsController
class AnnouncementsController < ApplicationController
  authorize_resource
  layout 'administration'

  def index
  	@announcements = Announcement.where(lecture: nil).order(:created_at)
  															 .reverse)
  end

  def new
  	@lecture = Lecture.find_by_id(params[:lecture])
  	@announcement = Announcement.new(announcer: current_user, lecture: @lecture)
  end

  def create
    @announcement = Announcement.new(announcement_params)
    @announcement.announcer = current_user
    @announcement.save
    if @announcement.valid?
    	create_notifications
    	unless @announcement.lecture.present?
	      redirect_to announcements_path
  	    return
  	  end
  	  redirect_to edit_lecture_path(@announcement.lecture)
  	  return
    end
    @errors = @announcement.errors[:details].join(', ')
  end

  private

  def announcement_params
    params.require(:announcement).permit(:details, :lecture_id)
  end

  def create_notifications
  	users_to_notify = if @announcement.lecture.present?
  											@announcement.lecture.users
  										else
  											User
  										end
  	notifications = []
  	users_to_notify.find_each do |u|
      notifications << Notification.new(recipient: u, notifiable_id: @announcement.id,
                          notifiable_type: 'Announcement', action: 'create')
    end
    Notification.import notifications
  end
end