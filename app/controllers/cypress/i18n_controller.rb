module Cypress
  # Allows to access i18n keys in Cypress tests.
  class I18nController < CypressController
    def create
      unless params[:i18n_key].is_a?(String)
        msg = "Argument `i18n_key` must be a string indicating the i18n key."
        msg += " But we got: '#{params[:i18n_key]}'"
        raise(ArgumentError, msg)
      end

      substitutions = {}
      if params[:substitutions].present?
        begin
          substitutions = params[:substitutions].to_unsafe_hash.symbolize_keys
        rescue NoMethodError
          msg = "Argument `substitution` is '#{params[:substitutions]}'."
          msg += " We cannot convert that to  a hash."
          raise(ArgumentError, msg)
        end
      end

      i18n_key = params[:i18n_key]
      render json: I18n.t(i18n_key, **substitutions), status: :created
    end
  end
end
