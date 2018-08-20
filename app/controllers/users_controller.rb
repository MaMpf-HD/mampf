# TermsController
class UsersController < ApplicationController
  authorize_resource

  def index
    @elevated_users = User.where(admin: true)
                          .or(User.where(editor: true))
                          .or(User.where.not(teacher: nil)).to_a
    @generic_users = User.where(admin: [false, nil], editor: [false, nil],
                                teacher: nil).to_a
  end

  def search
    @user = User.find(params[:user_id])
  end

  def destroy
  end
end
