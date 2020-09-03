# Remarks controller
class RemarksController < MediaController
  before_action :set_remark, only: [:edit, :update]
  before_action :set_quizzes, only: [:reassign]
  authorize_resource
  layout 'administration'

  def edit
    I18n.locale = @remark.locale_with_inheritance
  end

  def update
    @success = true if @remark.update(remark_params)
  end

  def reassign
    remark_old = Remark.find_by_id(params[:id])
    I18n.locale = remark_old.locale_with_inheritance
    @remark = remark_old.duplicate
    @remark.editors = [current_user]
    @quizzes.each do |q|
      Quiz.find_by_id(q).replace_reference!(remark_old, @remark)
    end
    I18n.locale = @remark.locale_with_inheritance
    if remark_params[:type] == 'edit'
      redirect_to edit_remark_path(@remark)
      return
    end
    @quizzable = @remark
    @mode = 'reassigned'
    render 'events/fill_quizzable_area'
  end

  private

  def set_remark
    @remark = Remark.find_by_id(params[:id])
    return if @remark.present?
    redirect_to remarks_path, alert: I18n.t('controllers.no_remark')
  end

  def set_quizzes
    @quizzes = params[:remark].select { |_k, v| v == '1' }.keys
                              .map { |k| k.remove('quiz-').to_i }
  end

  def remark_params
    params.require(:remark).permit(:text, :text_input, :type)
  end
end
