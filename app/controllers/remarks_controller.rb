# Remarks controller
class RemarksController < MediaController
  before_action :set_remark
#  before_action :set_quizzes, only: [:reassign]
  layout 'administration'

  # def update
  #   pp remark_params
  #   @remark.update(remark_params)
  #   @errors = @medium.errors
  #   return unless @errors.empty?
  #   # make sure the medium is touched
  #   # (it will not be touched automatically in some cases (e.g. if you only
  #   # update the associated tags), causing trouble for caching)
  #   @medium.touch
  #   # detach the video or manuscript if this was chosen by the user
  #   detach_video_or_manuscript
  # end

  # def index
  #   @remarks = Remark.order(:id).page params[:page]
  #   @remark = Remark.new
  # end

  # def new
  #   @remark = Remark.new
  # end

  # def create
  #   @remark = Remark.create_prefilled(remark_params[:label])
  #   redirect_to remark_path(@remark) if @remark.valid?
  # end

  # def show
  # end

  # def update
  #   @success = true if @remark.update(remark_params)
  # end

  # def destroy
  #   flash[:error] = 'Fehler beim Löschen der Bemerkung!' unless @remark.destroy
  #   redirect_to remarks_path
  # end

  # def reassign
  #   remark_old = Remark.find_by_id(params[:id])
  #   @remark = remark_old.duplicate
  #   @quizzes.each do |q|
  #     Quiz.find_by_id(q).replace_reference!(remark_old, @remark)
  #   end
  #   redirect_to remark_path(@remark) if remark_params[:type] == 'edit'
  # end

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
    params.require(:remark).permit(:sort, :description, :video, :manuscript,
                                   :external_reference_link, :teachable_type,
                                   :teachable_id, :released, :text,
                                   editor_ids: [],
                                   tag_ids: [],
                                   linked_medium_ids: [])
  end
end
