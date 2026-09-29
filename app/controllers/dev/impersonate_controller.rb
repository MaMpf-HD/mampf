module Dev
  class ImpersonateController < BaseController
    def create
      user = User.find(params[:id])
      bypass_sign_in(user)
      redirect_to(root_path)
    end
  end
end
