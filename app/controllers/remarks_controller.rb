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
    @remark = remark_old.duplicate
    @quizzes.each do |q|
      Quiz.find_by_id(q).replace_reference!(remark_old, @remark)
    end
    I18n.locale = @remark.locale_with_inheritance
    redirect_to edit_remark_path(@remark) if remark_params[:type] == 'edit'
  end

  private

  def set_remark
    @remark = Remark.find_by_id(params[:id])
    return if @remark.present?
    redirect_to remarks_path, alert: 'Eine Bemerkung mit der angeforderten id '\
                                     'existiert nicht.'
  end

  def set_quizzes
    @quizzes = params[:remark].select { |_k, v| v == '1' }.keys
                              .map { |k| k.remove('quiz-').to_i }
  end

  def remark_params
    params.require(:remark).permit(:text, :type)
  end
end
