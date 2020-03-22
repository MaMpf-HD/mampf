# AreasController
class AreasController < ApplicationController
  before_action :set_area, only: [:edit, :update, :destroy]
  authorize_resource

	def edit
	end

	def new
		@area = Area.new(subject_id: params[:subject_id].to_i)
	end

	def update
		@area.update(area_params)
		redirect_to classification_path
	end

	def create
		@area = Area.new(area_params)
		@area.subject_id = params[:area][:subject_id]
		@area.save
		redirect_to classification_path
	end

	def destroy
		@area.destroy
		redirect_to classification_path
	end

  private

  def set_area
    @area = Area.find_by_id(params[:id])
    return if @area.present?

    redirect_to root_path, alert: I18n.t('controllers.no_area')
  end

  def area_params
  	params.require(:area).permit(*Area.globalize_attribute_names)
  end
end