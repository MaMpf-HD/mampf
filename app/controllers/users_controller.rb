# TermsController
class UsersController < ApplicationController
  authorize_resource

  def index
    @admins = User.where(admin: true)
    @teachers_no_admin = User.where(admin: false).where(teacher: true)
    @generic_users = User.where(admin: [false, nil], teacher: [false, nil])
  end
end
