module Cypress
  # Allows to access i18n keys in Cypress tests.
  class I18nController < CypressController
    def create
      unless params[:i18n_key].is_a?(String)
        msg = "Argument `i18n_key` must be a string indicating the i18n key."
        msg += " But we got: '#{params[:i18n_key]}'"
        raise(ArgumentError, msg)
      end

      if params[:substitutions].blank? && !params[:substitutions].is_a?(Hash)
        msg = "Argument `substitution` must be a hash indicating the substitutions."
        msg += " But we got: '#{params[:substitutions]}'"
        raise(ArgumentError, msg)
      end

      i18n_key = params[:i18n_key]
      substitutions = params[:substitutions].to_unsafe_hash.symbolize_keys

      render json: { "value" => I18n.t(i18n_key, **substitutions) }, status: :created
    end
  end
end
