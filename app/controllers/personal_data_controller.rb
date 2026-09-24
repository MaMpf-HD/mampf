# Asks every user once for the name and matriculation number the university
# knows them by. What is saved stays as it is unless the support changes it;
# a field left empty may be filled in later.
class PersonalDataController < ApplicationController
  layout "devise"
  helper PersonalDataHelper
  # The page is where the user goes before going back, not where to return to.
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

    @user.assign_attributes(personal_data_params)
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

    # Only the fields still empty: what is saved is the support's to change.
    def personal_data_params
      params.fetch(:user, {}).permit(:name, *current_user.open_personal_data_fields,
                                     :no_matriculation_number, :personal_data_confirmation)
    end

    def after_personal_data_path
      session.delete(:after_personal_data).presence || start_path
    end
end
