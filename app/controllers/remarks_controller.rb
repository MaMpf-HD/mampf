# Remarks controller
class RemarksController < MediaController
  before_action :set_remark, except: :reassign
  before_action :set_quizzes, only: [:reassign]
  authorize_resource except: :reassign
  layout "administration"

  def current_ability
    @current_ability ||= RemarkAbility.new(current_user)
  end

  def edit
    I18n.locale = @remark.locale_with_inheritance
  end

  def update
    @success = true if @remark.update(remark_params)
  end

  def reassign
    remark_old = Remark.find_by(id: params[:id])
    authorize! :reassign, remark_old
    I18n.locale = remark_old.locale_with_inheritance
    @remark = remark_old.duplicate
    @remark.editors = [current_user]
    @quizzes.each do |q|
      Quiz.find_by(id: q).replace_reference!(remark_old, @remark)
    end
    I18n.locale = @remark.locale_with_inheritance
    if remark_params[:type] == "edit"
      redirect_to edit_remark_path(@remark)
      return
    end
    @quizzable = @remark
    @mode = "reassigned"
    render "media/fill_quizzable_area"
  end

  def cancel_remark_basics
  end

  private

    def set_remark
      @remark = Remark.find_by(id: params[:id])
      return if @remark.present?

      redirect_to remarks_path, alert: I18n.t("controllers.no_remark")
    end

    def set_quizzes
      @quizzes = params[:remark].select { |_k, v| v == "1" }.keys
                                .map { |k| k.remove("quiz-").to_i }
    end

    def remark_params
      params.expect(remark: [:text, :text_input, :type])
    end
end
