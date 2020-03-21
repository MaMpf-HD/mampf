# SubjectsController
class SubjectsController < ApplicationController
  before_action :set_subject, only: [:edit, :update]
  authorize_resource

  def new
  end

	def edit
	end

	def  update
		@subject.update(subject_params)
		redirect_to classification_path
	end

  private

  def set_subject
    @subject = Subject.find_by_id(params[:id])
    return if @subject.present?

    redirect_to root_path, alert: I18n.t('controllers.no_answers')
  end

  def subject_params
  	params.require(:subject).permit(*Subject.globalize_attribute_names)
  end
end