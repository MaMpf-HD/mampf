class MediaController < ApplicationController
  before_action :set_medium, only: [:show]
  authorize_resource

  def index
    @media = Medium.all
  end

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_medium
    @medium = Medium.find_by_id(params[:id])
    if !@medium.present?
      redirect_to :root, alert: 'Medium with requested id was not found.'
    end
  end
end
