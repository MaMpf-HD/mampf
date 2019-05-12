# RegistrationsController
class RegistrationsController < Devise::RegistrationsController
  def after_sign_up_path_for(resource)
    edit_profile_path
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation,
                                 :locale, :consents)
  end
end
