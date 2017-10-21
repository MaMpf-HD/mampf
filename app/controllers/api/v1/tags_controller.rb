# TagController for API
class Api::V1::TagsController < ApplicationController
  skip_before_action :authenticate_user!

  respond_to :json
  def show
    @tag = Tag.find(params[:id])
    render json: @tag
  end

  def index
    @tags = Tag.all
    render json: @tags, each_serializer: TagSerializer
  end
end
