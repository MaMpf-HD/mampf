# ClickersController
class ClickersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :edit, :open, :close,
                                                 :reset, :set_level,
                                                 :get_votes_count,
                                                 :set_alternatives,
                                                 :remove_question]
  before_action :set_clicker, except: [:new, :create]
  before_action :check_accessibility, only: [:edit, :open, :close, :set_level,
                                             :remove_question]
  authorize_resource
  layout 'clicker', except: [:edit]

  def new
    @clicker = Clicker.new
  end

  def edit
    @user_path = clicker_url(@clicker,
                             host: DefaultSetting::URL_HOST_SHORT).gsub('clickers','c')
    @editor_path = clicker_url(@clicker,
                               host: DefaultSetting::URL_HOST_SHORT,
                               params: { code: @clicker.code }).gsub('clickers','c')
    if user_signed_in?
      render layout: 'administration'
      return
    end
    render layout: 'edit_clicker'
  end

  def show
    if params[:code] == @clicker.code
      redirect_to edit_clicker_path(@clicker,
                                    params: { code: @clicker.code })
      return
    end
    if stale?(etag: @clicker, last_modified: @clicker.updated_at)
      render :show
      return
    end
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

  def set_alternatives
    @clicker.update(alternatives: params[:alternatives].to_i)
    head :ok, content_type: "text/html"
  end

  def get_votes_count
    result = @clicker.votes.count
    render json: result
  end

  def associate_question
    question = Question.find_by_id(clicker_params[:question_id])
    @clicker.update(question: question,
                    alternatives: question&.answers&.count || 3)
    redirect_to edit_clicker_path(@clicker)
  end

  def remove_question
    @clicker.update(question: nil,
                    alternatives: 3)
    redirect_to edit_clicker_path(@clicker)
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