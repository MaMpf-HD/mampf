# VerticesController
class VerticesController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_values
  before_action :set_update_vertex_params, only: [:update]
  before_action :set_create_vertex_params, only: [:create]

  def new
  end

  def create
    if @success
      @quiz.update(quiz_graph: @quiz.quiz_graph.create_vertex(@quizzable))
    end
    redirect_to edit_quiz_path(@quiz) if @sort == 'import'
  end

  def update
    @id = params[:id].to_i
    graph = @quiz.quiz_graph.update_vertex(@vertex_id, @default_id, @branching,
                                           @hide)
    @quiz.update(quiz_graph: graph)
    @quiz.save_png!
  end

  def destroy
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
    @default_id = @params_v[:default].to_i
    @branching = {}
    set_branching_hash
    set_hide_array
  end

  def set_create_vertex_params
    @sort = @params_v[:sort]
    if @sort == 'import'
      @quizzable = @params_v[:type].constantize
                                   .find_by_id(@params_v[:quizzable])
      @success = @quizzable.present?
    else
      @quizzable = @sort.constantize.create_prefilled(@params_v[:label])
      @success = @quizzable.valid?
    end
  end

  def set_branching_hash
    @branching = {}
    @params_v.keys.select { |k| k.start_with?('branching-') }.each do |k|
      @branching[k.remove('branching-').to_h] = [@vertex_id, @params_v[k].to_i]
    end
  end

  def set_hide_array
    @hide = @params_v.keys.select { |k| k.start_with?('hide-') }
                     .select { |h| @params_v[h] == '1' }
                     .map { |h| h.remove('hide-').to_h }
  end
end
