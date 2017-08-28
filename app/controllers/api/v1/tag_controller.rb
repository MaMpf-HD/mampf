class Api::V1::TagController < ApplicationController
  respond_to :json
  def show
    @tag = Tag.find(params[:id])
    render :json => @tag
  end
end
