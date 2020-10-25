# TermsController
class UsersController < ApplicationController
  before_action :set_elevated_users, only: [:index, :list_generic_users]
  authorize_resource
  layout 'administration'

  def index
    @generic_users = User.where.not(id: @elevated_users.pluck(:id))
  end

  def edit
    @user = User.find_by_id(params[:id])
  end

  def update
    @user = User.find_by_id(params[:id])
    @user.update(user_params)
    @errors = @user.errors
  end

  # promote a generic user to admin status
  def elevate
    @errors = {}
    @user = User.find(elevate_params[:id])
    admin = elevate_params[:admin] == '1'
    return unless admin
    # enforce a name
    if @user.name.blank?
      name = @user.email.split('@')[0]
      @user.update(admin: true, name: name)
    else
      @user.update(admin: true)
    end
  end

  def list
    search = User.search { fulltext params[:term] }
    @users = search.results
  end

  def list_generic_users
    result = User.where.not(id: @elevated_users.pluck(:id))
                 .map { |u| { value: u.id, text: u.info }}
    render json: result
  end

  def destroy
    @user = User.find_by_id(params[:id])
    @user.destroy unless @user.admin || @user.editor? || @user.teacher?
    redirect_to users_path
  end

  def teacher
    @teacher = User.find_by_id(params[:teacher_id])
    if @teacher.present? && @teacher.teacher?
      render layout: 'application'
      return
    end
    redirect_to :root,
                alert: I18n.t('controllers.no_teacher')
  end

  def fill_user_select
    result = User.pluck(:name, :email, :id)
                 .map { |u| { value: u.third,
                              text: "#{u.first} (#{u.second})" } }
    render json: result
  end

  def delete_account
  end

  private

  def elevate_params
    params.require(:generic_user).permit(:id, :admin, :editor, :teacher, :name)
  end

  def user_params
    params.require(:user).permit(:name, :email, :admin, :homepage,
                                 :current_lecture_id)
  end

  def set_elevated_users
    @elevated_users = User.where(admin: true).or(User.editors).or(User.teachers)
  end
end
