# MediaController
class MediaController < ApplicationController
  skip_before_action :authenticate_user!, only: [:play, :display]
  before_action :set_medium, except: [:index, :catalog, :new, :create, :search]
  before_action :set_course, only: [:index]
  before_action :check_project, only: [:index]
  before_action :set_teachable, only: [:new]
  before_action :sanitize_params
  before_action :check_for_consent, except: [:play, :display]
  authorize_resource
  layout 'administration'

  def index
    cookies[:current_course] = params[:course_id]
    @media = paginated_results
    render layout: 'application'
  end

  def catalog
    @media = Medium.all
  end

  def show
    render layout: 'application'
  end

  def new
    @medium = Medium.new(teachable: @teachable)
    @medium.editors << current_user
    tags = Tag.where(id: params[:tag_ids])
    @medium.tags << tags if tags.present?
  end

  def edit
  end

  def update
    @old_manuscript_destinations = @medium.manuscript_destinations
    @medium.update(medium_params)
    @errors = @medium.errors
    return unless @errors.empty?
    # detach the video or manuscript if this was chosen by the user
    detach_video_or_manuscript
    # if changes to the manuscript have been made, find out
    # whether named destination items are affected by the
    # changes. If this is the case, the user gets a warning
    # and can then decide whether to keep old items or to delete them
    if @medium.saved_change_to_manuscript_data?
      @protected_destinations = @medium.protected_destinations
      @medium.update_pdf_destinations!
      if @protected_destinations.present?
        render :destination_warning
        return
      end
    end
    redirect_to edit_medium_path(@medium)
  end

  def create
    @medium = Medium.new(medium_params)
    @medium.save
    if @medium.valid?
      # convert pdf destinations from extracted metadata to actual items
      @medium.create_pdf_destinations!
      redirect_to edit_medium_path(@medium)
      return
    end
    @errors = @medium.errors
    render :update
  end

  def destroy
    @medium.destroy
    redirect_to administration_path
  end

  def inspect
  end

  # return all media that match the search parameters
  def search
    @media = Medium.search_by_attributes(search_params)
  end

  # play the video using thyme player
  def play
    @toc = @medium.toc_to_vtt.remove(Rails.root.join('public').to_s)
    @ref = @medium.references_to_vtt.remove(Rails.root.join('public').to_s)
    @time = params[:time]
    render layout: 'thyme'
  end

  # show the pdf, optionally at specified page or named destination
  def display
    unless params[:destination].present?
      redirect_to @medium.manuscript_url unless params[:destination].present?
      return
    end
    redirect_to @medium.manuscript_url + '#' + params[:destination]
  end

  # add a toc item for the video
  def add_item
    @time = params[:time].to_f
    @item = Item.new(medium: @medium,
                     start_time: TimeStamp.new(total_seconds: @time))
  end

  # add a reference for the video
  def add_reference
    @time = params[:time].to_f
    @end_time = [@time + 60, @medium.video_duration].min
    @referral = Referral.new(medium: @medium,
                             start_time: TimeStamp.new(total_seconds: @time),
                             end_time: TimeStamp.new(total_seconds: @end_time))
    @item_selection = @medium.teachable.media_scope.media_items_with_inheritance
    @item = Item.new(sort: 'link')
  end

  # add a screenshot for the video
  def add_screenshot
    tempfile = Tempfile.new(['screenshot', '.png'])
    File.open(tempfile, 'wb') do |f|
      f.write params[:image].read
    end
    @medium.screenshot = File.open(tempfile)
    @medium.save
    respond_to do |format|
      format.js { render :add_screenshot }
    end
  end

  # remove the video's screenshot
  def remove_screenshot
    return if @medium.screenshot.nil?
    @medium.update(screenshot: nil)
  end

  # start the thyme editor
  def enrich
  end

  # export the video's toc data to a .vtt file
  def export_toc
    file = @medium.toc_to_vtt
    cookies['fileDownload'] = 'true'

    send_file file,
              filename: 'toc-' + @medium.title + '.vtt',
              type: 'content-type',
              x_sendfile: true
  end

  # export the video's references to a .vtt file
  def export_references
    file = @medium.references_to_vtt
    cookies['fileDownload'] = 'true'

    send_file file,
              filename: 'references-' + @medium.title + '.vtt',
              type: 'content-type',
              x_sendfile: true
  end

  # export the video's screenshot to a .vtt file
  def export_screenshot
    return if @medium.screenshot.nil?
    path = Rails.root.join('public', 'tmp')
    file = Tempfile.new(['screenshot', '.png'], path)
    @medium.screenshot.stream(file.path)
    cookies['fileDownload'] = 'true'

    send_file file,
              filename: 'screenshot-' + @medium.title + '.png',
              type: 'content-type',
              x_sendfile: true
  end

  # delete the items associated to the manuscript's pdf_destinations
  def delete_destinations
    @medium.destroy_pdf_destinations!(params[:destinations].to_a)
  end

  private

  def medium_params
    params.require(:medium).permit(:sort, :description, :video, :manuscript,
                                   :external_reference_link, :teachable_type,
                                   :teachable_id,
                                   editor_ids: [],
                                   tag_ids: [],
                                   linked_medium_ids: [])
  end

  def set_medium
    @medium = Medium.find_by_id(params[:id])
    return if @medium.present?
    redirect_to :root, alert: 'Ein Medium mit der angeforderten id existiert ' \
                              'nicht.'
  end

  def set_course
    @course = Course.find_by_id(params[:course_id])
    return if @course.present?
    redirect_to :root, alert: 'Ein Modul mit der angeforderten id ' \
                              'existiert nicht.'
  end

  def set_teachable
    if params[:teachable_type].in?(['Course', 'Lecture', 'Lesson']) &&
       params[:teachable_id].present?
      @teachable = params[:teachable_type].constantize
                                          .find_by_id(params[:teachable_id])
    end
  end

  def detach_video_or_manuscript
    if params[:medium][:detach_video] == 'true'
      @medium.update(video: nil)
      @medium.update(screenshot: nil)
    end
    return unless params[:medium][:detach_manuscript] == 'true'
    @medium.update(manuscript: nil)
  end

  def check_project
    return unless params[:project]
    return if @course.available_food.include?(params[:project])
    redirect_to :root, alert: 'Ein solches MaMpf-Teilprojekt existiert ' \
                              'für dieses Modul nicht.'
  end

  def sanitize_params
    sanitize_page!
    sanitize_per!
    params[:all] = params[:all] == 'true'
    params[:reverse] = params[:reverse] == 'true'
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end

  def paginated_results
    return Kaminari.paginate_array(search_results) if params[:all]
    Kaminari.paginate_array(search_results).page(params[:page])
            .per(params[:per])
  end

  def search_results
    search_results = Medium.search(@course.primary_lecture(current_user),
                                   params)
    return search_results unless params[:reverse]
    search_results.reverse
  end

  def sanitize_page!
    params[:page] = params[:page].to_i.positive? ? params[:page].to_i : 1
  end

  def sanitize_per!
    params[:per] = if params[:per].to_i.in?([3, 4, 8, 12, 24])
                     params[:per].to_i
                   else
                     8
                   end
  end

  def search_params
    params.require(:search).permit(:all_types, :all_teachables, :all_tags,
                                   :all_editors,
                                   types: [],
                                   teachable_ids: [],
                                   tag_ids: [],
                                   editor_ids: [])
  end
end
