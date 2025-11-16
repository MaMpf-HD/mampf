module Cypress
  # Creates a user for use in Playwright tests.
  class UserCreatorPlaywrightController < CypressController
    PASSWORD = "play".freeze

    def create
      unless params[:role].is_a?(String)
        msg = "Role argument must be a string indicating the user role."
        msg += " But we got: '#{params["0"]}'"
        raise(ArgumentError, msg)
      end

      id = params[:id].to_i
      role = params[:role]
      is_admin = (role == "admin")
      random_hash = SecureRandom.hex(6)

      user = User.create(name: "#{role} (#{id})",
                         email: "#{role}-#{id}-#{random_hash}@play",
                         name_in_tutorials: "#{role} (public, #{id})",
                         password: PASSWORD,
                         consents: true,
                         admin: is_admin,
                         locale: :en)
      user.confirm

      render json: user.as_json.merge({ password: PASSWORD }), status: :created
    end
  end
end
