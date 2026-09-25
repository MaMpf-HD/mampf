# Sets the locale for the current user based on their preferences.
module LocaleSetter
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  private

    def set_locale
      I18n.locale = locale_param || current_user.try(:locale) ||
                    cookie_locale_param || browser_locale || I18n.default_locale
      set_pagy_locale

      return if respond_to?(:user_signed_in?) && user_signed_in?
      return unless locale_param && request.get?

      cookies[:locale] = locale_param
    end

    # Saves the language picked on the personal data page, so that a form
    # error and the next page stay in it.
    def remember_locale_choice
      return unless user_signed_in? && locale_param && request.get?
      return if current_user.locale == locale_param

      current_user.update(locale: locale_param)
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

    def browser_locale
      offered = request.headers["Accept-Language"].to_s.split(",").filter_map do |entry|
        tag, *parameters = entry.split(";").map(&:strip)
        weight = parameters.find { |p| p.start_with?("q=") }&.delete_prefix("q=")
        weight = weight ? weight.to_f : 1.0
        code = tag.to_s.downcase.split("-").first
        [code, weight] if weight.positive? && code.in?(available_locales)
      end
      offered.max_by { |_code, weight| weight }&.first
    end

    def available_locales
      I18n.available_locales.map(&:to_s)
    end
end
