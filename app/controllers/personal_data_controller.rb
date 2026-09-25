class PersonalDataController < ApplicationController
  layout "devise"
  helper PersonalDataHelper
  helper_method :place_lecture_ids
  # Keeps Devise's stored return path from pointing at this page.
  skip_before_action :store_user_location!
  before_action :remember_locale_choice, only: :edit

  def edit
    @user = current_user
    ask
  end

  def update
    @user = current_user
    ask
    @participation = params[:participation]
    return decline if @asking && @participation == "no"

    @user.assign_attributes(personal_data_params.merge(math_program_params))
    @user.personal_data_confirmed_at ||= Time.current
    if @user.save(context: :personal_data)
      redirect_to after_personal_data_path, notice: t("personal_data.saved")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

    def ask
      @asking = personal_data_due?
      @places = Rosters::UserPlaces.new(@user)
      @place_lectures = @asking ? @places.lectures : []
      @results_recorded = @place_lectures.any? && @places.results?
    end

    # A no from a student with places gives the places up, but only those of
    # the lectures the form named. The ids it sends back are compared with the
    # student's current lectures, and a place that is not among them makes
    # the form come back with the new list rather than go unseen.
    def decline
      return render_places_graded if @results_recorded

      @user.assign_attributes(name: params.dig(:user, :name) || @user.name,
                              personal_data_declined_at: Time.current)
      return render_places_changed if params[:give_up_places].to_s != place_lecture_ids
      return render(:edit, status: :unprocessable_content) unless @user.valid?

      ActiveRecord::Base.transaction do
        @places.give_up!(@place_lectures) if @place_lectures.any?
        @user.save!
      end
      redirect_to after_personal_data_path
    rescue Rosters::UserPlaces::PlacesChangedError
      ask
      render_places_changed
    rescue Rosters::MaintenanceService::GradingDataPresentError
      render_places_graded
    end

    def place_lecture_ids
      @place_lectures.map(&:id).join(",")
    end

    def render_places_changed
      flash.now[:alert] = t("personal_data.places_changed")
      render :edit, status: :unprocessable_content
    end

    def render_places_graded
      @results_recorded = true
      flash.now[:alert] = t("personal_data.places_graded")
      render :edit, status: :unprocessable_content
    end

    def personal_data_params
      permitted = params.fetch(:user, {})
                        .permit(:name, *current_user.open_personal_data_fields,
                                :no_matriculation_number, :personal_data_confirmation)
      return permitted unless ActiveModel::Type::Boolean.new.cast(
        permitted[:no_matriculation_number]
      )

      permitted.except(:matriculation_number)
    end

    # A student of two subjects who answered that mathematics is one of them
    # gets its program; the page picks it in the browser too, but not without
    # JavaScript.
    def math_program_params
      degree = params[:study_degree]
      return {} unless degree.in?(Program::TWO_SUBJECT_DEGREES) && params[:study_math] == "yes"

      program = Program.joins(:subject).find_by(degree: degree, subjects: { key: Subject::MATH })
      program ? { program_id: program.id } : {}
    end

    def after_personal_data_path
      session.delete(:after_personal_data).presence || start_path
    end
end
