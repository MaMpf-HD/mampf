# ClickersController
class ClickersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :edit]
  before_action :set_clicker, except: [:new, :create]
  before_action :check_accessibility, only: [:edit]
  authorize_resource
  layout 'administration'

  def new
    @clicker = Clicker.new
  end

  def edit
    @user_path = clicker_url(@clicker).gsub('clickers','c')
    @editor_path = clicker_url(@clicker,
                               params: { code: @clicker.code }).gsub('clickers','c')
    render layout: false if !user_signed_in?
  end

  def show
    if params[:code] == @clicker.code
      redirect_to edit_clicker_path(@clicker,
                                    params: { code: @clicker.code })
      return
    end
    render layout: false
  end

  def create
    @clicker = Clicker.new(clicker_params)
    @clicker.save
    if @clicker.valid?
      redirect_to administration_path
      return
    end
    @errors = @clicker.errors
  end

  private

  def clicker_params
    params.require(:clicker).permit(:editor_id, :teachable_type,
                                    :teachable_id, :question_id, :title)
  end

  def set_clicker
    @clicker = Clicker.find_by_id(params[:id])
    return if @clicker
    redirect_to :root, alert: I18n.t('controllers.no_clicker')
  end

  def check_accessibility
    if user_signed_in?
      return if current_user.admin || current_user == @clicker.editor
    else
      return if params[:code] == @clicker.code
    end
    redirect_to :root, alert: I18n.t('controllers.no_clicker_access')
  end
end