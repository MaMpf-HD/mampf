# SectionController
class SectionsController < ApplicationController
  before_action :set_section, only: [:show, :reset, :update]
  authorize_resource

  def show
  end

  def reset
  end

  def update
    @section.update(section_params)
    @errors = @section.errors
  end

  def list_tags
    @tags = Tag.where(id: JSON.parse(params[:tags])).sort_by(&:title)
    @id = params[:id]
  end

  private

  def set_section
    @section = Section.find_by_id(params[:id])
    return if @section.present?
    redirect_to :root, alert: 'Ein Abschnitt mit der angeforderten id existiert
                               nicht.'
  end

  def section_params
    params.require(:section).permit(:title, :display_number, tag_ids: [],
                                                             lesson_ids: [])
  end
end
