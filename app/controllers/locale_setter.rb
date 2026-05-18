# Sets the locale for the current user based on their preferences.
module LocaleSetter
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  private

    def set_locale
      I18n.locale = current_user.try(:locale) || locale_param ||
                    cookie_locale_param || I18n.default_locale
      set_pagy_locale
      return if respond_to?(:user_signed_in?) && user_signed_in?

      cookies[:locale] = I18n.locale
    end

    def set_pagy_locale
      Pagy::I18n.locale = I18n.locale.to_s
    end

    def locale_param
      return unless params[:locale].in?(available_locales)

      params[:locale]
    end

    def cookie_locale_param
      return unless cookies[:locale].in?(available_locales)

      cookies[:locale]
    end

    def available_locales
      I18n.available_locales.map(&:to_s)
    end
end
