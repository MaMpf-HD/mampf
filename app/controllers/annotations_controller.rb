class AnnotationsController < ApplicationController

  def create
    @annotation = Annotation.new(annotation_params)
    @annotation.user_id = current_user.id
    @annotation.category = helpers.category_text_to_int(
                           params[:annotation][:category_text])
    @annotation.save
  end

  def edit
    @annotation = Annotation.find(params[:annotationId])
    @timestamp = @annotation.timestamp
    @medium_id = @annotation.medium_id
    # A variable that helps to assign the correct text to
    # the given category, e.g. "Need help!" for the category 'help'.
    @category_text = helpers.category_token_to_text(@annotation.category)
  end

  def new
    @annotation = Annotation.new
    @timestamp = params[:timestamp]
    @medium_id = params[:mediumId]
  end

  def show
    @annotation = Annotation.find(params[:id])
  end

  def update
    @annotation = Annotation.find(params[:id])
    @annotation.category = helpers.category_text_to_int(
                           params[:annotation][:category_text])
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
        :color, :comment, :medium_id,
        :timestamp, :visible_for_teacher)
    end

end
