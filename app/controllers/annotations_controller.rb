class AnnotationsController < ApplicationController
  
  authorize_resource
  
  def create
    # Create new annotation and add additional attributes which are not covered by the form
    @annotation = Annotation.new(annotation_params)
    @total_seconds = params[:annotation][:total_seconds]
    @annotation.timestamp = TimeStamp.new(total_seconds: @total_seconds)
    @annotation.user_id = current_user.id
    
    # Convert checkbox string "1" into the boolean true
    if params[:annotation][:post_as_comment] == "1"
      @post_as_comment = true
    else
      @post_as_comment = false
    end

    # Post comment
    if @post_as_comment == true
      @medium = Medium.find_by_id(params[:annotation][:medium_id])
      @link = 'Thymestamp: <a href="' + play_medium_path(@medium) +
        '?time=' + @total_seconds + '">' + @annotation.timestamp.hms_colon_string + '</a>'
      @comment = annotation_params[:comment] + "\n" + @link
      @commontator_thread = @medium.commontator_thread
      @comment = Commontator::Comment.new(
        thread: @commontator_thread, creator: @current_user, body: @comment
      )
      @comment.save
      @annotation.public_comment_id = @comment.id
    end

    @annotation.save
    render :update
  end

  def edit
    @annotation = Annotation.find(params[:annotationId])
    # only allow editing, if the current user created the annotation
    if @annotation.user_id != current_user.id
      render json: false
      return
    end
    @total_seconds = @annotation.timestamp.total_seconds
    @medium_id = @annotation.medium_id
  end

  def new
    @annotation = Annotation.new(category: :note, color: Annotation.colors[1])
    @total_seconds = params[:total_seconds]
    @medium_id = params[:mediumId]
    render :edit
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

  def update_annotations
    medium = Medium.find_by_id(params[:mediumId])

    # Get the right annotations
    if medium.annotations_visible?(current_user)
      annotations = Annotation.where(medium: medium,
                                     visible_for_teacher: true).or(
                    Annotation.where(medium: medium,
                                     user: current_user))
    else
      annotations = Annotation.where(medium: medium,
                                user: current_user)
    end
    
    # Convert to JSON (for easier hash operations)
    annotations = annotations.as_json

    # Filter attributes and add boolean "belongs_to_current_user".
    annotations.each do |a|
      a['belongs_to_current_user'] = (current_user.id == a['user_id'])
      a.slice!('category', 'color', 'comment', 'id',
               'belongs_to_current_user', 'timestamp', 'subtext')
    end

    render json: annotations
  end

  def num_nearby_mistake_annotations
    annotations = Annotation.where(medium: params[:mediumId])
    radius = params[:radius].to_i
    timestamp = params[:timestamp].to_i
    counter = 0
    for annotation in annotations
      if annotation.category == "mistake" &&
         (annotation.timestamp.total_seconds - timestamp).abs() < radius &&
         annotation.public_comment_id != nil
        counter += 1
      end
    end
    render json: counter
  end
  
  def current_ability
    @current_ability ||= AnnotationAbility.new(current_user)
  end



  private

    def annotation_params
      params.require(:annotation).permit(
        :category, :color, :comment, :medium_id, :subtext, :visible_for_teacher)
    end

end
