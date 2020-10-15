# RegistrationsController
class RegistrationsController < Devise::RegistrationsController

  def destroy
    success = resource.archive_and_destroy(deletion_params[:archive_name])
    if !success
      set_flash_message :alert, :not_destroyed
      respond_with_navigational(resource){ redirect_to after_sign_up_path_for(resource_name) }
      return
    end
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message :notice, :destroyed
    yield resource if block_given?
    respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
  end

  def after_sign_up_path_for(resource)
    edit_profile_path
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation,
                                 :locale, :consents)
  end

  def deletion_params
    params.permit(:archive_name)
  end
end
