class AnnotationsController < ApplicationController

  def create
    @annotation = Annotation.new(annotation_params)
    @total_seconds = params[:annotation][:total_seconds]
    @annotation.timestamp = TimeStamp.new(total_seconds: @total_seconds)
    @annotation.user_id = current_user.id
    @annotation.save

    @publish = params[:annotation][:publish]
    if @publish == "1" #= corresponding checkbox is marked
      @medium = Medium.find_by_id(params[:annotation][:medium_id])
      @link = 'Link zur entsprechenden Stelle im Video: <a href="' + play_medium_path(@medium) +
        '?time=' + @total_seconds + '">' + @annotation.timestamp.hms_colon_string + '</a>'
      @comment = params[:annotation][:comment] + "\n" + @link
      @commontator_thread = @medium.commontator_thread
      @comment = Commontator::Comment.new(
        thread: @commontator_thread, creator: @current_user, body: @comment
      )
      @comment.save
    end
  end

  def edit
    @annotation = Annotation.find(params[:annotationId])
    @total_seconds = @annotation.timestamp.total_seconds
    @medium_id = @annotation.medium_id
  end

  def new
    @annotation = Annotation.new(category: :note, color: helpers.annotation_color(1))
    @total_seconds = params[:total_seconds]
    @medium_id = params[:mediumId]
  end

  def show
    @annotation = Annotation.find(params[:id])
  end

  def update
    @annotation = Annotation.find(params[:id])
    @annotation.update(annotation_params)
  end

  def destroy
    Annotation.find(params[:annotationId]).destroy
    render json: []
  end

  def update_markers
    medium = Medium.find_by_id(params[:mediumId])
    toggled = params[:toggled]

    if medium.annotations_visible?(current_user) && toggled == "true"
      annots = Annotation.where(medium: medium,
                                visible_for_teacher: true).or(
               Annotation.where(medium: medium,
                                user: current_user))
    else
      annots = Annotation.where(medium: medium,
                                user: current_user)
    end

    render json: annots
  end



  private

    def annotation_params
      params.require(:annotation).permit(
        :category, :color, :comment, :medium_id, :visible_for_teacher)
    end

end
