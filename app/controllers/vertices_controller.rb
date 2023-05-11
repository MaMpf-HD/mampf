# VerticesController
class VerticesController < ApplicationController
  before_action :set_values
  # note that we do not use cancancan's authorization methods in the actions
  # as we could not get it to work here
  # it seems not to accept the quiz parameter:
  # authorize! :new, :vertex, @quiz
  # ---> calls VertexAbility#can, but does not pass the @quiz param, hence
  # an exception
  # authorize! :new, @quiz
  # ---> does not call VertexAbility#can
  before_action :check_permission
  before_action :set_update_vertex_params, only: [:update]
  before_action :set_create_vertex_params, only: [:create]

  def current_ability
    @current_ability = VertexAbility.new(current_user)
  end

  def new
    # authorize! :new, @quiz
  end

  def create
    # authorize! :create, @quiz
    if @success
      @quizzables.each do |q|
        @quiz.update(quiz_graph: @quiz.quiz_graph.create_vertex(q))
      end
    end
    redirect_to edit_quiz_path(@quiz)
  end

  def update
    # authorize! :update, @quiz
    @id = params[:id].to_i
    graph = @quiz.quiz_graph.update_vertex(@vertex_id, @branching,
                                           @hide)
    @quiz.update(quiz_graph: graph)
    redirect_to edit_quiz_path(@quiz)
  end

  def destroy
    # authorize! :destroy, @quiz
    @id = params[:id].to_i
    quiz_graph = @quiz.quiz_graph
    @quiz.update(quiz_graph: quiz_graph.destroy_vertex(@id))
    redirect_to edit_quiz_path(@quiz)
  end

  private

    def set_values
      @quiz_id = params[:quiz_id]
      @quiz = Quiz.find_by_id(@quiz_id)
      @params_v = params[:vertex]
    end

    def set_update_vertex_params
      @vertex_id = @params_v[:vertex_id].to_i
      @branching = {}
      set_branching_hash
      set_hide_array
    end

    def set_create_vertex_params
      @sort = @params_v[:sort]
      if @sort == 'import'
        @quizzables = Medium.where(id: @params_v[:quizzable_ids],
                                   type: ['Question', 'Remark'])
        @success = @quizzables.any?
      else
        quizzable = @sort.constantize.create_prefilled(@params_v[:label],
                                                       @quiz.teachable,
                                                       @quiz.editors)
        @success = quizzable.valid?
        @quizzables = [quizzable]
      end
    end

    def set_branching_hash
      @branching = {}
      @params_v.keys.select { |k| k.start_with?('branching-') }.each do |k|
        next if @params_v[k].to_i == 0

        @branching[k.remove('branching-').to_h] =
          [@vertex_id, @params_v[k].to_i]
      end
    end

    def set_hide_array
      @hide = @params_v.keys.select { |k| k.start_with?('hide-') }
                       .select { |h| @params_v[h] == '1' }
                       .map { |h| h.remove('hide-').to_h }
    end

    def check_permission
      return if current_user.admin
      return if current_user.can_edit?(@quiz)

      redirect_to :root, alert: I18n.t('controllers.unauthorized')
    end
end
