# ClickersController
class ClickersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :edit, :open, :close,
                                                 :reset]
  before_action :set_clicker, except: [:new, :create]
  before_action :check_accessibility, only: [:edit, :open, :close, :reset]
  authorize_resource
  layout 'clicker', except: [:edit]

  def new
    @clicker = Clicker.new
  end

  def edit
    @user_path = clicker_url(@clicker).gsub('clickers','c')
    @editor_path = clicker_url(@clicker,
                               params: { code: @clicker.code }).gsub('clickers','c')
    if user_signed_in?
      render layout: 'administration'
      return
    end
    render layout: 'edit_clicker'
  end

  def show
    pp cookies['clicker-#{@clicker.id}']
    pp @clicker.instance
    if params[:code] == @clicker.code
      redirect_to edit_clicker_path(@clicker,
                                    params: { code: @clicker.code })
      return
    end
    pp stale?(@clicker)
    if stale?(etag: @clicker, last_modified: @clicker.updated_at)
      render :show
      return
    end
  end

  def decline

  end

  def create
    @clicker = Clicker.new(clicker_params)
    @clicker.save
    if @clicker.valid?
      redirect_to administration_path
      return
    end
    @errors = @clicker.errors
    render layout: 'administration'
  end

  def open
    @clicker.open!
    render layout: 'administration' if user_signed_in?
  end

  def close
    @clicker.close!
    render layout: 'administration' if user_signed_in?
  end

  def reset
    @clicker.reset!
    render layout: 'administration' if user_signed_in?
  end

  private

  def clicker_params
    params.require(:clicker).permit(:editor_id, :teachable_type,
                                    :teachable_id, :question_id, :title)
  end

  def set_clicker
    @clicker = Clicker.find_by_id(params[:id])
    @code = user_signed_in? ? nil : @clicker&.code
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