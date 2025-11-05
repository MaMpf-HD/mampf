module Cypress
  # Creates a user for use in Playwright tests.
  class UserCreatorPlaywrightController < CypressController
    PASSWORD = "play".freeze

    def create
      unless params[:role].is_a?(String)
        msg = "First argument must be a string indicating the user role."
        msg += " But we got: '#{params["0"]}'"
        raise(ArgumentError, msg)
      end

      id = params[:id].to_i
      role = params[:role]
      is_admin = (role == "admin")

      user = User.create(name: "#{id} - #{role}",
                         email: "#{id}@play",
                         name_in_tutorials: "#{id} - #{role}",
                         password: PASSWORD,
                         consents: true,
                         admin: is_admin,
                         locale: :en)
      user.confirm

      render json: user.as_json.merge({ password: PASSWORD }), status: :created
    end
  end
end
