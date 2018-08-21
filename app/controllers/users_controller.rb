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

  def elevate
    @errors = {}
    @user = User.find(elevate_params[:id])
    admin = elevate_params[:admin] == '1'
    editor = elevate_params[:editor] == '1'
    if elevate_params[:teacher] == '1' && elevate_params[:teacher_name].blank?
      @errors[:teacher_name] = ['Es muss ein DozentInnenname angegeben werden.']
      return
    end
    @user.update(admin: admin, editor: editor, name: elevate_params[:name])
    unless @user.valid?
      @errors = @user.errors
      return
    end
    return unless elevate_params[:teacher] == '1'
    teacher = Teacher.where(name: elevate_params[:teacher_name]).first
    puts teacher
    if teacher.present?
      @user.update(teacher: teacher)
    else
      puts 'Hier'
      teacher = Teacher.create(name: elevate_params[:teacher_name],
                               email: @user.email)
      @user.update(teacher: teacher)
    end
  end

  def destroy
  end

  private

  def elevate_params
    params.require(:generic_user).permit(:id, :admin, :editor, :teacher, :name,
                                         :teacher_name)
  end
end
