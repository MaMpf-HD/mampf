class Api::V1::TagsController < ApplicationController
  respond_to :json
  def show
    @tag = Tag.find(params[:id])
    render :json => @tag
  end

  def index
    @tags = Tag.all
    render :json => @tags
  end
end
