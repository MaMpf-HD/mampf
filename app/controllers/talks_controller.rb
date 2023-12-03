# TalksController
class TalksController < ApplicationController
  before_action :set_talk, except: [:new, :create]
  authorize_resource except: [:new, :create]
  before_action :set_view_locale, only: [:edit]
  layout "administration"

  def current_ability
    @current_ability ||= TalkAbility.new(current_user)
  end

  def show
    render layout: "application_no_sidebar"
  end

  def new
    @lecture = Lecture.find_by(id: params[:lecture_id])
    @talk = Talk.new(lecture: @lecture)
    authorize! :new, @talk
    I18n.locale = @talk.lecture.locale_with_inheritance ||
                  current_user.locale || I18n.default_locale
  end

  def edit
  end

  def create
    @talk = Talk.new(talk_params)
    authorize! :create, @talk
    dates = params[:talk][:dates].values.compact - [""]
    @talk.dates = dates if dates
    I18n.locale = @talk&.lecture&.locale_with_inheritance ||
                  current_user.locale || I18n.default_locale
    position = params[:talk][:predecessor]
    # place the chapter in the correct position
    if position.present?
      @talk.insert_at(position.to_i + 1)
    else
      @talk.save
    end
    redirect_to edit_lecture_path(@talk.lecture) if @talk.valid?
    @errors = @talk.errors
  end

  def update
    I18n.locale = @talk.lecture.locale_with_inheritance ||
                  current_user.locale || I18n.default_locale
    dates = params[:talk][:dates]&.values&.compact.to_a - [""]
    @talk.update(talk_params)
    @talk.update(dates: dates) if dates && @talk.valid?
    if @talk.valid?
      predecessor = params[:talk][:predecessor]
      # place the chapter in the correct position
      if predecessor.present?
        position = predecessor.to_i
        position -= 1 if position > @talk.position
        @talk.insert_at(position + 1)
      end
      redirect_to edit_talk_path(@talk)
      return
    end
    @errors = @talk.errors
  end

  def destroy
    lecture = @talk.lecture
    @talk.destroy
    redirect_to edit_lecture_path(lecture)
  end

  def assemble
    render layout: "application_no_sidebar"
  end

  # modify is the update action for speakers of the talk
  # only few columns are allowed to be modified
  def modify
    @talk.update(modify_params)
    redirect_to assemble_talk_path(@talk)
  end

  private

    def set_talk
      @talk = Talk.find_by(id: params[:id])
      return if @talk.present?

      redirect_to :root, alert: I18n.t("controllers.no_talk")
    end

    def talk_params
      attributes = [:title, :lecture_id, :details, :description,
                    :display_description, { speaker_ids: [], tag_ids: [] }]
      if @talk && !current_user.in?(@talk.speakers) &&
         !@talk.display_description
        attributes.delete(:display_description)
      end
      params.require(:talk).permit(attributes)
    end

    def modify_params
      params.require(:talk).permit(:description, :display_description,
                                   tag_ids: [])
    end

    def set_view_locale
      I18n.locale = @talk.lecture.locale_with_inheritance ||
                    current_user.locale || I18n.default_locale
    end
end
