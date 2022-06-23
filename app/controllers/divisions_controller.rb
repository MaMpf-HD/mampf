# DivisionsController
class DivisionsController < ApplicationController
  before_action :set_division, except: [:new, :create]
  authorize_resource except: [:new, :create]

  def current_ability
    @current_ability ||= DivisionAbility.new(current_user)
  end

	def edit
	end

	def new
		@division = Division.new(program_id: params[:program_id].to_i)
    authorize! :new, @division
	end

	def update
		@division.update(division_params)
		redirect_to classification_path
	end

	def create
		@division = Division.new(division_params)
		@division.program_id = params[:division][:program_id]
    authorize! :create, @division
		@division.save
		redirect_to classification_path
	end

	def destroy
		@division.destroy
		redirect_to classification_path
	end

  private

  def set_division
    @division = Division.find_by_id(params[:id])
    return if @division.present?

    redirect_to root_path, alert: I18n.t('controllers.no_division')
  end

  def division_params
  	params.require(:division).permit(*Division.globalize_attribute_names)
  end
end