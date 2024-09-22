module Cypress
  # Creates a user for use in Cypress tests.
  class UserCreatorController < CypressController
    CYPRESS_PASSWORD = "cypress123".freeze

    def create
      unless params[:role].is_a?(String)
        msg = "First argument must be a string indicating the user role."
        msg += " But we got: '#{params["0"]}'"
        raise(ArgumentError, msg)
      end

      role = params[:role]
      is_admin = (role == "admin")

      user = User.create(name: "#{role} Cypress", email: "#{role}@mampf.cypress",
                         name_in_tutorials: "#{role} Real Cypress Name",
                         password: CYPRESS_PASSWORD, consents: true,
                         admin: is_admin, locale: I18n.default_locale)
      user.confirm

      render json: user.as_json.merge({ password: CYPRESS_PASSWORD }),
             status: :created
    end
  end
end
