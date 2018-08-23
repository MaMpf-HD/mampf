# TermsController
class UsersController < ApplicationController
  authorize_resource

  def index
    @elevated_users = User.where(admin: true).to_a | User.editors |
                      User.teachers
    @generic_users = User.all.to_a - @elevated_users
  end

  def edit
    @user = User.find_by_id(params[:id])
  end

  def update
    @user = User.find_by_id(params[:id])
    @user.update(user_params)
    @errors = @user.errors
  end

  def elevate
    @errors = {}
    @user = User.find(elevate_params[:id])
    admin = elevate_params[:admin] == '1'
    return unless admin
    if @user.name.blank?
      name = @user.email.split('@')[0]
      @user.update(admin: true, name: name)
    else
      @user.update(admin: true)
    end
    redirect_to users_path
  end

  def destroy
    @user = User.find_by_id(params[:id])
    @user.destroy unless @user.admin || @user.editor? || @user.teacher?
    redirect_to users_path
  end

  def teacher
    @teacher = User.find_by_id(params[:teacher_id])
    return if @teacher.present? && @teacher.teacher?
    redirect_to :root,
                alert: 'Ein(e) DozentIn mit der angeforderten id existiert ' \
                       'nicht.'
  end

  private

  def elevate_params
    params.require(:generic_user).permit(:id, :admin, :editor, :teacher, :name)
  end

  def user_params
    params.require(:user).permit(:name, :email, :admin, :homepage)
  end
end
