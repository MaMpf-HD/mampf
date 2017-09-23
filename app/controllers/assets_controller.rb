class AssetsController < ApplicationController
  before_action :set_asset
  authorize_resource

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_asset
    @asset = Asset.find_by_id(params[:id])
    if !@asset.present?
      redirect_to :root, alert: 'Asset with requested id was not found.'
    end
  end
end
