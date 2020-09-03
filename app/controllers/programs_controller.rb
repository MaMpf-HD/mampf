# ProgramsController
class ProgramsController < ApplicationController
  before_action :set_program, only: [:edit, :update, :destroy]
  authorize_resource

	def edit
	end

	def new
		@program = Program.new(subject_id: params[:subject_id].to_i)
	end

	def update
		@program.update(program_params)
		redirect_to classification_path
	end

	def create
		@program = Program.new(program_params)
		@program.subject_id = params[:program][:subject_id].to_i
		@program.save
		redirect_to classification_path
	end

	def destroy
		@program.destroy
		redirect_to classification_path
	end

  private

  def set_program
    @program = Program.find_by_id(params[:id])
    return if @program.present?

    redirect_to root_path, alert: I18n.t('controllers.no_program')
  end

  def program_params
  	params.require(:program).permit(*Program.globalize_attribute_names)
  end
end