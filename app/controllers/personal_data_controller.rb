# Asks every user once for the name and matriculation number the university
# knows them by. What is saved stays as it is unless the support changes it;
# a field left empty may be filled in later.
class PersonalDataController < ApplicationController
  layout "devise"
  # The page is where the user goes before going back, not where to return to.
  skip_before_action :store_user_location!

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @user.assign_attributes(personal_data_params)
    @user.personal_data_confirmed_at ||= Time.current
    if @user.save(context: :personal_data)
      redirect_to after_personal_data_path, notice: t("personal_data.saved")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def decline
    if current_user.personal_data_pending?
      current_user.update!(personal_data_declined_at: Time.current)
    end
    redirect_to after_personal_data_path
  end

  private

    # Only the fields still empty: what is saved is the support's to change.
    def personal_data_params
      params.fetch(:user, {}).permit(*current_user.open_personal_data_fields,
                                     :no_matriculation_number, :personal_data_confirmation)
    end

    def after_personal_data_path
      stored_location_for(:user).presence || start_path
    end
end
