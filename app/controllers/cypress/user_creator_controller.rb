module Cypress
  # Creates a user for use in Cypress tests.
  class UserCreatorController < CypressController
    def create
      unless params[:role].is_a?(String)
        msg = "First argument must be a string indicating the user role."
        msg += " But we got: '#{params["0"]}'"
        raise(ArgumentError, msg)
      end

      role = params[:role]
      is_admin = (role == "admin")
      random_hash = SecureRandom.hex(6)

      user = User.create(name: "#{role} Cypress #{random_hash}",
                         email: "#{role}-#{random_hash}@mampf.cypress",
                         password: "cypress123", consents: true, admin: is_admin,
                         locale: I18n.default_locale)
      user.confirm

      render json: user.to_json, status: :created
    end
  end
end
