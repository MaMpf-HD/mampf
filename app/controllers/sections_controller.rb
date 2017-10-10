class SectionsController < ApplicationController
  before_action :set_section, only: [:show]
  authorize_resource

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_section
    @section = Section.find_by_id(params[:id])
    if !@section.present?
      redirect_to :root, alert: 'Ein Abschnitt mit der angeforderten id existiert nicht.'
    end
  end
end
