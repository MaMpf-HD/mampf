# Events controller
# Deals with all AJAX actions in Quizzes
class EventsController < ApplicationController
#  authorize_resource class: false

  def update_vertex_default
    @quizzable = Quiz.find_by_id(params[:quiz_id]).quizzable(params[:id].to_i)
    @vertex_id = params[:vertex_id].to_i
  end

  def update_branching
    @quizzable = Quiz.find_by_id(params[:quiz_id])
                     .quizzable(params[:vertex_id].to_i)
    @id = params[:id].sub 'select', 'quizzable'
    @hide_id = params[:id].sub 'branching_select', 'hide'
  end

  def new_vertex_quizzables
    @type = params[:type]
    @quizzables = @type.constantize.all
                       .map { |q| { value: q.id, text: q.label }}.to_json
  end

  def new_vertex_quizzable_text
    @type = params[:type]
    @id = params[:id]
    @quizzable = @type.constantize.find_by_id(@id)
  end

  def update_vertex_body
    @quiz = Quiz.find(params[:quiz_id])
    @vertex_id = params[:vertex_id].to_i
  end

  def update_answer_body
    @answer = Answer.find_by_id(params[:answer_id])
    @question = @answer.question
    @input = params[:input]
  end

  def update_answer_box
    @answer_id = params[:answer_id].to_i
    @value = params[:value] == 'true'
  end

  def cancel_question_basics
    @question = Question.find_by_id(params[:question_id])
  end

  def cancel_remark_basics
    @remark = Remark.find_by_id(params[:remark_id])
  end

  def cancel_quiz_basics
    @quiz = Quiz.find_by_id(params[:quiz_id])
  end

  def fill_quizzable_modal
    @id = params[:id]
    @type = params[:type]
    @quizzable = @type.constantize.find_by_id(@id)
  end

  def fill_reassign_modal
    @type = params[:type]
    @quizzable = @type.constantize.find_by_id(params[:id])
    @in_quiz = params[:in_quiz] == 'true'
    @quiz_id = params[:quiz_id].to_i
  end
end
