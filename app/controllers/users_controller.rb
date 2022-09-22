# TermsController
class UsersController < ApplicationController
  before_action :set_elevated_users, only: [:index, :list_generic_users]
  layout 'administration'

  def current_ability
    @current_ability ||= UserAbility.new(current_user)
  end

  def index
    authorize! :index, User.new
    @generic_users = User.where.not(id: @elevated_users.pluck(:id))
  end

  def edit
    @user = User.find_by_id(params[:id])
    authorize! :edit, @user
  end

  def update
    @user = User.find_by_id(params[:id])
    authorize! :update, @user
    old_image_data = @user.image_data
    @user.update(user_params)
    @errors = @user.errors
    @user.update(image: nil) if params[:user][:detach_image] == 'true'
    changed_image = @user.image_data != old_image_data
    if @user.image.present? && changed_image
      @user.image_derivatives!
      @user.save
    end
    @errors = @user.errors
  end

  # promote a generic user to admin status
  def elevate
    authorize! :elevate, User.new
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
    authorize! :destroy, @user
    @user.destroy unless @user.admin || @user.editor? || @user.teacher?
    redirect_to users_path
  end

  def teacher
    @teacher = User.find_by_id(params[:teacher_id])
    authorize! :teacher, @teacher
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
    authorize! :delete_account, User.new
  end

  private

  def elevate_params
    params.require(:generic_user).permit(:id, :admin, :editor, :teacher, :name)
  end

  def user_params
    params.require(:user).permit(:name, :email, :admin, :homepage,
                                 :current_lecture_id,:image)
  end

  def set_elevated_users
    @elevated_users = User.where(admin: true).or(User.proper_editors)
                          .or(User.teachers)
  end

  def search_params
    params.require(:search).permit(:name)
  end

  def search
    authorize! :search, User.new
    search = User.search_by(search_params, params[:page])
    search.execute
    results = search.results
    @total = search.total
    @lectures = Kaminari.paginate_array(results, total_count: @total)
                        .page(params[:page]).per(search_params[:per])
  end
end
