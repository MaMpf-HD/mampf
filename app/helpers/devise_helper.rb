module DeviseHelper
  def devise_links(resource_name, devise_mapping, resource_class, controller_name)
    links = []

    if controller_name != "sessions"
      links << link_to(t(".login"),
                       new_session_path(resource_name, params: { locale: I18n.locale }))
    end

    if devise_mapping.registerable? && controller_name != "registrations"
      links << link_to(t("devise.registrations.new.sign_up"),
                       new_registration_path(resource_name, params: { locale: I18n.locale }))
    end

    if devise_mapping.confirmable? && controller_name != "confirmations"
      links << link_to(
        t(".didn_t_receive_confirmation_instructions"),
        new_confirmation_path(resource_name, params: { locale: I18n.locale })
      )
    end

    if devise_mapping.lockable? \
        && resource_class.unlock_strategy_enabled?(:email) \
        && controller_name != "unlocks"
      links << link_to(t(".didn_t_receive_unlock_instructions"),
                       new_unlock_path(resource_name))
    end

    links
  end
end
