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

    respond_to do |format|
      format.js do
        Rails.logger.warn("[MUESLI-DEPRECATION] Legacy JS format accessed in " \
                          "TalksController#new")
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "modal-container",
          partial: "talks/roster_modal",
          locals: { talk: @talk }
        )
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "modal-container",
          partial: "talks/roster_modal",
          locals: { talk: @talk }
        )
      end
    end
  end

  def create
    @talk = Talk.new(talk_params)
    authorize! :create, @talk

    dates = parse_talk_dates(params[:talk][:dates])
    @talk.dates = dates

    I18n.locale = @talk&.lecture&.locale_with_inheritance ||
                  current_user.locale || I18n.default_locale
    position = params[:talk][:predecessor]

    saved = if position.present?
      @talk.insert_at(position.to_i + 1)
      @talk.valid?
    else
      @talk.save
    end

    respond_to do |format|
      format.js do
        Rails.logger.warn("[MUESLI-DEPRECATION] Legacy JS format accessed in " \
                          "TalksController#create")
        if saved
          redirect_to edit_lecture_path(@talk.lecture)
        else
          @errors = @talk.errors
          render :create
        end
      end
      format.turbo_stream do
        group_type = parse_group_type
        streams = create_turbo_streams(group_type, saved)
        render turbo_stream: streams, status: saved ? :ok : :unprocessable_content
      end
    end
  end

  def update
    I18n.locale = @talk.lecture.locale_with_inheritance ||
                  current_user.locale || I18n.default_locale
    if @talk.update(talk_params) && @talk.valid?
      dates = parse_talk_dates(params[:talk][:dates])
      @talk.update(dates: dates)

      predecessor = params[:talk][:predecessor]
      # place the chapter in the correct position
      if predecessor.present?
        position = predecessor.to_i
        position -= 1 if position > @talk.position
        @talk.insert_at(position + 1)
      end

      flash.now[:notice] = t("controllers.talks.updated")

      respond_to do |format|
        format.html { redirect_to edit_talk_path(@talk) }
        format.turbo_stream do
          group_type = parse_group_type
          render turbo_stream: [
            update_roster_groups_list_stream(group_type),
            refresh_campaigns_index_stream(@talk.lecture),
            turbo_stream.update("modal-container", ""),
            stream_flash
          ].compact
        end
      end
      return
    end

    @errors = @talk.errors
    respond_to do |format|
      format.html { render :edit }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(@talk, "form"),
          partial: "talks/roster_modal_form",
          locals: { talk: @talk }
        ), status: :unprocessable_content
      end
    end
  end

  def destroy
    lecture = @talk.lecture
    if @talk.destroy
      flash.now[:notice] = t("controllers.talks.destroyed")
    else
      flash.now[:alert] = t("controllers.talks.destruction_failed")
    end

    respond_to do |format|
      format.html do
        Rails.logger.warn("[MUESLI-DEPRECATION] Legacy HTML format accessed in " \
                          "TalksController#destroy")
        redirect_to edit_lecture_path(lecture)
      end
      format.turbo_stream do
        group_type = parse_group_type
        render turbo_stream: [
          update_roster_groups_list_stream(group_type),
          refresh_campaigns_index_stream(lecture),
          stream_flash
        ].compact
      end
    end
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
      attributes = [:title, :lecture_id, :details, :description, :capacity,
                    :display_description, { speaker_ids: [], tag_ids: [] }]
      if @talk && !current_user.in?(@talk.speakers) &&
         !@talk.display_description
        attributes.delete(:display_description)
      end
      params.expect(talk: attributes)
    end

    def modify_params
      params.expect(talk: [:description, :display_description,
                           { tag_ids: [] }])
    end

    def set_view_locale
      I18n.locale = @talk.lecture.locale_with_inheritance ||
                    current_user.locale || I18n.default_locale
    end

    def parse_talk_dates(dates_param)
      return [] unless dates_param

      dates_param.values.filter_map { |d| d[:date] }.compact_blank
    end

    def parse_group_type
      if params[:group_type].is_a?(Array)
        params[:group_type].map(&:to_sym)
      else
        params[:group_type].presence&.to_sym || :talks
      end
    end

    def create_turbo_streams(group_type, saved)
      streams = []

      if saved
        flash.now[:notice] = t("controllers.talks.created")
        streams << update_roster_groups_list_stream(group_type)
        streams << refresh_campaigns_index_stream(@talk.lecture)
        streams << turbo_stream.update("modal-container", "")
      else
        streams << turbo_stream.replace(view_context.dom_id(@talk, "form"),
                                        partial: "talks/roster_modal_form",
                                        locals: { talk: @talk })
      end

      streams << stream_flash if flash.present?
      streams
    end

    def update_roster_groups_list_stream(group_type)
      component = RosterOverviewComponent.new(lecture: @talk.lecture,
                                              group_type: group_type)
      turbo_stream.update("roster_groups_list",
                          partial: "roster/components/groups_tab",
                          locals: {
                            groups: component.groups,
                            group_type: group_type,
                            component: component
                          })
    end

    def refresh_campaigns_index_stream(lecture)
      turbo_stream.replace("campaigns_container",
                           partial: "registration/campaigns/index",
                           locals: { lecture: lecture })
    end
end
