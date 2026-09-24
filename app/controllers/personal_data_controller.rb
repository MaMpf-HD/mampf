class PersonalDataController < ApplicationController
  layout "devise"
  helper PersonalDataHelper
  # Keeps Devise's stored return path from pointing at this page.
  skip_before_action :store_user_location!
  before_action :remember_locale_choice, only: :edit

  def edit
    @user = current_user
    @asking = @user.personal_data_pending?
  end

  def update
    @user = current_user
    @asking = @user.personal_data_pending?
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

    def decline
      @user.assign_attributes(name: params.dig(:user, :name) || @user.name,
                              personal_data_declined_at: Time.current)
      if @user.save
        redirect_to after_personal_data_path
      else
        render :edit, status: :unprocessable_content
      end
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
