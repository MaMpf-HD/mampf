# ClickersController
class ClickersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :edit, :open, :close,
                                                 :votes_count,
                                                 :set_alternatives,
                                                 :render_clickerizable_actions]
  before_action :set_clicker, except: [:new, :create]
  authorize_resource except: [:new, :create, :edit, :open, :close,
                              :set_alternatives]
  layout "clicker", except: [:edit]

  def current_ability
    @current_ability ||= ClickerAbility.new(current_user)
  end

  def show
    if params[:code] == @clicker.code
      redirect_to edit_clicker_path(@clicker,
                                    params: { code: @clicker.code })
      return
    end
    if stale?(etag: @clicker,
              last_modified: [@clicker.updated_at,
                              Time.zone.parse(ENV.fetch("RAILS_CACHE_ID", nil))].max)
      render :show
      nil
    end
  end

  def new
    @clicker = Clicker.new
    authorize! :new, @clicker
  end

  def edit
    authorize! :edit, @clicker, @entered_code
    @user_path = clicker_url(@clicker,
                             host: DefaultSetting::URL_HOST_SHORT)
                 .gsub("clickers", "c")
    @editor_path = clicker_url(@clicker,
                               host: DefaultSetting::URL_HOST_SHORT,
                               params: { code: @clicker.code })
                   .gsub("clickers", "c")
    if user_signed_in?
      render layout: "administration"
      return
    end
    render layout: "edit_clicker"
  end

  def create
    @clicker = Clicker.new(clicker_params)
    authorize! :create, @clicker
    @clicker.save
    if @clicker.valid?
      redirect_to administration_path
      return
    end
    @errors = @clicker.errors
    render layout: "administration"
  end

  def destroy
    @clicker.destroy
    redirect_to administration_path
  end

  def open
    authorize! :open, @clicker, @entered_code
    @clicker.open!
    render layout: "administration" if user_signed_in?
  end

  def close
    authorize! :close, @clicker, @entered_code
    @clicker.close!
    render layout: "administration" if user_signed_in?
  end

  def set_alternatives
    authorize! :set_alternatives, @clicker, @entered_code
    @clicker.update(alternatives: params[:alternatives].to_i)
    head :ok, content_type: "text/html"
  end

  def votes_count
    result = @clicker.votes.count
    render json: result
  end

  def associate_question
    question = Question.find_by(id: clicker_params[:question_id])
    @clicker.update(question: question,
                    alternatives: question&.answers&.count || 3)
    redirect_to edit_clicker_path(@clicker)
  end

  def remove_question
    @clicker.update(question: nil,
                    alternatives: 3)
    code = user_signed_in? ? nil : @clicker.code
    redirect_to edit_clicker_path(@clicker,
                                  params: { code: code })
  end

  def render_clickerizable_actions
    I18n.locale = current_user.locale
    @medium = Medium.find_by(id: params[:medium_id])
    @question = Question.find_by(id: params[:medium_id])
  end

  private

    def clicker_params
      params.require(:clicker).permit(:editor_id, :teachable_type,
                                      :teachable_id, :question_id, :title)
    end

    def code_params
      params.permit(:code)
    end

    def set_clicker
      @clicker = Clicker.find_by(id: params[:id])
      @code = user_signed_in? ? nil : @clicker&.code
      @entered_code = code_params[:code]
      return if @clicker

      redirect_to :root, alert: I18n.t("controllers.no_clicker")
    end
end
