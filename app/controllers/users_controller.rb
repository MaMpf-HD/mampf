# TermsController
class UsersController < ApplicationController
  authorize_resource

  def index
    @elevated_users = User.where(admin: true)
                          .or(User.where(editor: true)).to_a | User.teachers
    @generic_users = User.all.to_a - @elevated_users
  end

  def elevate
    @errors = {}
    @user = User.find(elevate_params[:id])
    admin = elevate_params[:admin] == '1'
    editor = elevate_params[:editor] == '1'
    @user.update(admin: admin, editor: editor, name: elevate_params[:name])
    unless @user.valid?
      @errors = @user.errors
      return
    end
  end

  def destroy
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
end
