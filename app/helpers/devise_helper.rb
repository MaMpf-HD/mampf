module DeviseHelper
  # Where the language switch on a Devise page has to point.
  #
  # Devise re-renders the form on a failed submit, so the current request is a
  # POST or PUT and `url_for` would build the submit path -- following that as
  # a link lands somewhere else entirely. The reset form needs its token
  # carried over on top of that.
  def devise_locale_switch_path(locale)
    case [controller_name, action_name]
    when ["registrations", "create"]
      new_user_registration_path(locale: locale)
    when ["registrations", "update"]
      edit_user_registration_path(locale: locale)
    when ["passwords", "create"]
      new_user_password_path(locale: locale)
    when ["passwords", "edit"], ["passwords", "update"]
      edit_user_password_path(locale: locale,
                              reset_password_token: reset_password_token)
    else
      url_for(locale: locale)
    end
  end

  def devise_links(resource_name, devise_mapping, resource_class, controller_name)
    links = []

    if controller_name != "sessions"
      links << link_to(t("devise.shared.links.login"),
                       new_session_path(resource_name, params: { locale: I18n.locale }))
    end

    if devise_mapping.registerable? && controller_name != "registrations"
      links << link_to(t("devise.registrations.new.sign_up"),
                       new_registration_path(resource_name, params: { locale: I18n.locale }))
    end

    if devise_mapping.confirmable? && controller_name != "confirmations"
      links << link_to(
        t("devise.shared.links.didn_t_receive_confirmation_instructions"),
        new_confirmation_path(resource_name, params: { locale: I18n.locale })
      )
    end

    if devise_mapping.lockable? \
        && resource_class.unlock_strategy_enabled?(:email) \
        && controller_name != "unlocks"
      links << link_to(t("devise.shared.links.didn_t_receive_unlock_instructions"),
                       new_unlock_path(resource_name))
    end

    links
  end

  private

    def reset_password_token
      params[:reset_password_token] ||
        params[:user].try(:dig, :reset_password_token)
    end
end
