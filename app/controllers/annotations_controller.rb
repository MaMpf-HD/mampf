class AnnotationsController < ApplicationController

  before_action :update_comments, only: [:edit, :update_annotations]

  authorize_resource

  def new
    @annotation = Annotation.new(category: :note, color: Annotation.colors[1])
    @total_seconds = params[:total_seconds]
    @medium_id = params[:mediumId]
    @posted = (@annotation.public_comment_id != nil)

    render :edit
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
    @posted = (@annotation.public_comment_id != nil)
  end

  def update
    @annotation = Annotation.find(params[:id])
    comment_id = @annotation.public_comment_id
    if (comment_id == nil)
      @annotation.public_comment_id = post_comment
    else
      medium = Medium.find_by_id(params[:annotation][:medium_id])
      total_seconds = params[:annotation][:total_seconds]
      comment = params[:annotation][:comment]
      commontator_comment = Commontator::Comment.find_by(id: comment_id)
      commontator_comment.update(editor: current_user,
                                 body: comment_html(medium, total_seconds, comment))
    end
    @annotation.update(annotation_params)
  end

  def create
    @annotation = Annotation.new(annotation_params)
    @annotation.user_id = current_user.id
    @total_seconds = params[:annotation][:total_seconds]
    @annotation.timestamp = TimeStamp.new(total_seconds: @total_seconds)
    @annotation.public_comment_id = post_comment

    @annotation.save
    render :update
  end

  def show
    @annotation = Annotation.find(params[:id])
  end

  def destroy
    annotation = Annotation.find(params[:annotationId])
    comment = Commontator::Comment.find_by(id: annotation.public_comment_id)
    comment.update(deleted_at: DateTime.now)
    annotation.destroy
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
               'belongs_to_current_user', 'timestamp', 'subcategory')
    end

    render json: annotations
  end

  def num_nearby_mistake_annotations
    annotations = Annotation.where(medium: params[:mediumId])
    # the time (!) radius in which annotation are considered as "nearby"
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
        :category, :color, :comment, :medium_id, :subcategory, :visible_for_teacher)
    end

    def post_comment
      if params[:annotation][:post_as_comment] == "1"
        medium = Medium.find_by_id(params[:annotation][:medium_id])
        total_seconds = params[:annotation][:total_seconds]
        commontator_thread = medium.commontator_thread
        commontator_comment = Commontator::Comment.new(
          thread: commontator_thread,
          creator: current_user,
          body: comment_html = comment_html(medium,
                                            total_seconds,
                                            annotation_params[:comment])
        )
        commontator_comment.save
        return commontator_comment.id
      end
    end

    def comment_html(medium, total_seconds, comment)
      timestamp = TimeStamp.new(total_seconds: total_seconds).hms_colon_string
      return comment + "\n" +
             'Thymestamp: <a href="' + play_medium_path(medium) +
             '?time=' + total_seconds + '">' + timestamp + '</a>'
    end

    def update_comments
      Annotation.where(medium: params[:mediumId]).each do |annotation|
        # find comment
        unless annotation.public_comment.nil?
          comment = annotation.public_comment.body

          # remove "Thymestamp: H:MM:SS" at the end of the string
          index = comment.rindex("\nThymestamp")
          annotation.update(comment: comment[0 .. index - 1]) unless index == nil
        end
      end
    end

end
