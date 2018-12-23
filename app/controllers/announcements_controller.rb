# AnnouncementsController
class AnnouncementsController < ApplicationController
  authorize_resource
  layout 'administration'

  def index
  	@announcements = Kaminari.paginate_array(Announcement.where(lecture: nil)
  																											 .order(:created_at)
  															 												 .reverse)
  													 .page(params[:page]).per(10)
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
end