class TagsController < ApplicationController
  before_action :set_tag, only: [:show]
  authorize_resource

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tag
    @tag = Tag.find_by_id(params[:id])
    if !@tag.present?
      redirect_to :root, alert: 'Tag with requested id was not found.'
    end
  end
end
