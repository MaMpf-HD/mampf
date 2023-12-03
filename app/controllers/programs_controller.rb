# ProgramsController
class ProgramsController < ApplicationController
  before_action :set_program, except: [:new, :create]
  authorize_resource except: [:new, :create]

  def current_ability
    @current_ability ||= ProgramAbility.new(current_user)
  end

  def new
    @program = Program.new(subject_id: params[:subject_id].to_i)
    authorize! :new, @program
  end

  def edit
  end

  def create
    @program = Program.new(program_params)
    @program.subject_id = params[:program][:subject_id].to_i
    authorize! :create, @program
    @program.save
    redirect_to classification_path
  end

  def update
    @program.update(program_params)
    redirect_to classification_path
  end

  def destroy
    @program.destroy
    redirect_to classification_path
  end

  private

    def set_program
      @program = Program.find_by(id: params[:id])
      return if @program.present?

      redirect_to root_path, alert: I18n.t("controllers.no_program")
    end

    def program_params
      params.require(:program).permit(*Program.globalize_attribute_names)
    end
end
