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
      # trigger creation of notifications for all relevant users
      create_notifications
      # redirection depending from where the announcement was created
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
    users_to_notify.where(no_notifications: false).find_each do |u|
      notifications << Notification.new(recipient: u,
                                        notifiable_id: @announcement.id,
                                        notifiable_type: 'Announcement',
                                        action: 'create')
    end
    # use activerecord-import gem to use only one SQL instruction
    Notification.import notifications
  end
end
