class AnnotationsController < ApplicationController

  authorize_resource

  def new
    @annotation = Annotation.new(category: :note, color: Annotation.colors[1])

    @total_seconds = params[:total_seconds]
    @medium_id = params[:medium_id]
    @posted = false

    render :edit
  end

  def edit
    @annotation = Annotation.find(params[:annotation_id])

    # only allow editing, if the current user created the annotation
    if @annotation.user_id != current_user.id
      render json: false
      return
    end

    @total_seconds = @annotation.timestamp.total_seconds
    @medium_id = @annotation.medium_id
    @posted = !@annotation.public_comment_id.nil?

    # if this annotation has an associated commontator comment,
    # we have to call the "get_comment" method in order to get
    # the text.
    @annotation.comment = @annotation.get_comment
  end

  def create
    @annotation = Annotation.new(annotation_params)

    @annotation.user_id = current_user.id
    @total_seconds = annotation_auxiliary_params[:total_seconds]
    @annotation.timestamp = TimeStamp.new(total_seconds: @total_seconds)

    return unless create_and_update_shared(@annotation)

    @annotation.save
    render :update
  end

  def update
    @annotation = Annotation.find(params[:id])
    @annotation.assign_attributes(annotation_params)

    return unless create_and_update_shared(@annotation)

    @annotation.save
  end

  def show
    @annotation = Annotation.find(params[:id])
  end

  def destroy
    annotation = Annotation.find(params[:annotation_id])

    # only the owner of the annotation is allowed to delete it
    return unless annotation.user == current_user

    # delete associated commontator comment
    unless annotation.public_comment_id.nil?
      commontator_comment = Commontator::Comment.find_by(id: annotation.public_comment_id)
      commontator_comment.update(deleted_at: DateTime.now)
    end

    annotation.destroy

    render json: []
  end

  def update_annotations
    medium = Medium.find_by(id: params[:mediumId])

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

    # If annotation is associated to a comment,
    # the field "comment" is empty -> get it from the commontator comment
    annotations.each do |a|
      a.comment = a.get_comment
    end

    # Convert to JSON (for easier hash operations)
    annotations = annotations.as_json

    # Filter attributes and add boolean "belongs_to_current_user".
    annotations.each do |a|
      public_comment_id = a['public_comment_id']
      a['belongs_to_current_user'] = (current_user.id == a['user_id'])
      a.slice!('belongs_to_current_user', 'category', 'color', 'comment',
               'id', 'subcategory', 'timestamp')
    end

    render json: annotations
  end

  def num_nearby_posted_mistake_annotations
    annotations = Annotation.where(medium: params[:mediumId], category: 'mistake').commented
    # the time (!) radius in which annotation are considered as "nearby"
    radius = params[:radius].to_i
    timestamp = params[:timestamp].to_i
    counter = annotations.to_a.count { |annotation| annotation.nearby?(timestamp, radius) }
    render json: counter
  end

  def current_ability
    @current_ability ||= AnnotationAbility.new(current_user)
  end



  private

    def annotation_params
      params.require(:annotation).permit(
        :category, :color, :comment, :medium_id, :subcategory, :visible_for_teacher
      )
    end

    def annotation_auxiliary_params
      params.require(:annotation).permit(
        :total_seconds, :post_as_comment
      )
    end
    
    def valid_color?(color)
      color&.match?(/\A#([0-9]|[A-F]){6}\z/)
    end

    def valid_time?(annotation)
      time = annotation.timestamp.total_seconds
      time >= 0 and time <= annotation.medium.video["duration"]
    end

    # checks that the subcategory is non-nil if the category is "content" and
    # resets the subcategory to "nil" if the selected category isn't "content"
    def subcategory_nil(annotation)
      return if annotation.category_for_database == Annotation.categories[:content] and
                annotation.subcategory.nil?
      if annotation.category_for_database != Annotation.categories[:content]
        annotation.subcategory = nil
      end
      return true
    end

    # common code for the create and update method
    def create_and_update_shared(annotation)
      return unless valid_color?(annotation.color) and
                    valid_time?(annotation) and
                    subcategory_nil(annotation)
      annotation.public_comment_id = post_comment(annotation)
      return true
    end

    # Run all the Commontator::Comment related code here
    def post_comment(annotation)
      public_comment_id = annotation.public_comment_id

      # return if checkbox "post_as_comment" is not checked and if there is no comment to update
      return if annotation_auxiliary_params[:post_as_comment] != '1' and public_comment_id.nil?

      comment = annotation_params[:comment]

      if public_comment_id.nil? # comment doesn't exist yet -> create one
        medium = annotation.medium
        commontator_comment = Commontator::Comment.create(
          thread: medium.commontator_thread,
          creator: current_user,
          body: comment,
          annotation: annotation
        )
      else # comment already exists -> update it
        commontator_comment = Commontator::Comment.find_by(id: public_comment_id)
        commontator_comment.update(editor: current_user,
                                     body: comment)
      end

      # delete comment as it is already saved in the commontator comment model
      annotation.comment = nil

      commontator_comment.id
    end

end
