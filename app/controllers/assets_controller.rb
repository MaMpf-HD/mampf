class AssetsController < ApplicationController
  before_action :set_asset

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_asset
    @asset = Asset.find(params[:id])
  end
end
