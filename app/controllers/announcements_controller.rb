# AnnouncementsController
class AnnouncementsController < ApplicationController
	before_action :set_announcement, only: [:edit, :update]
  authorize_resource
  layout 'administration'

  def index
  	@announcements = Announcement.where(lecture: nil)
  end

  def edit
  end

  def update
    @announcement.update(announcement_params)
    unless @announcement.valid?
	    @errors = @announcement.errors[:details].join(', ')
	  end
  end

  private

  def set_announcement
    @id = params[:id]
    @announcement = Announcement.find_by_id(@id)
    return if @announcement.present?
    redirect_to announcements_path, 
    						alert: 'Ein Semester mit der angeforderten id ' \
                       'existiert nicht.'
  end

  def announcement_params
    params.require(:announcement).permit(:details) 	
  end
end