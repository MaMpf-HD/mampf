class AnnotationsController < ApplicationController

  def create
    @annotation = Annotation.new(annotation_params)
    @annotation.user_id = current_user.id
    @annotation.category = category_translation
    @annotation.save
  end

  def edit
    @annotation = Annotation.find(params[:annotationId])
    @timestamp = @annotation.timestamp
    @medium_id = @annotation.medium_id
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

    def category_translation
      category = params[:annotation][:category_text]
      case category
      when 'Need help!'
        return Annotation.categories[:help]
      when 'Found a mistake'
        return Annotation.categories[:mistake]
      when 'Give a comment'
        return Annotation.categories[:comment]
      when 'Note'
        return Annotation.categories[:note]
      when 'Other'
        return Annotation.categories[:other]
      end
    end

end
