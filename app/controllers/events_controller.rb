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

  def update_vertex_body
    @quiz = Quiz.find(params[:quiz_id])
    I18n.locale = @quiz.locale_with_inheritance
    @vertex_id = params[:vertex_id].to_i
  end

  def update_answer_body
    @answer = Answer.find_by_id(params[:answer_id])
    @question = @answer.question
    I18n.locale = @question.locale_with_inheritance
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
    I18n.locale = @quizzable.locale_with_inheritance
  end

  def fill_quizzable_preview
    @id = params[:id]
    @type = params[:type]
    @quizzable = @type.constantize.find_by_id(@id)
    I18n.locale = @quizzable.locale_with_inheritance
  end

  def fill_medium_preview
    @id = params[:id]
    @medium = Medium.find_by_id(@id)
    I18n.locale = current_user.locale
  end

  def render_medium_actions
    @id = params[:id]
    @medium = Medium.find_by_id(@id)
    I18n.locale = current_user.locale
  end

  def render_import_vertex
    @id = params[:id]
    @type = params[:type]
    @quiz_id = params[:quiz_id]
    I18n.locale = Quiz.find_by_id(@quiz_id)&.locale_with_inheritance
  end

  def render_vertex_quizzable
    @quiz = Quiz.find_by_id(params[:quiz_id])
    @vertex_id = params[:id].to_i
    @quizzable = @quiz.quizzable(@vertex_id)
  end

  def edit_vertex_targets
    @quiz = Quiz.find_by_id(params[:quiz_id])
    @vertex_id = params[:id].to_i
  end

  def cancel_import_vertex
    quiz_id = params[:quiz_id]
    I18n.locale = Quiz.find_by_id(quiz_id)&.locale_with_inheritance
  end

  def fill_reassign_modal
    @type = params[:type]
    @quizzable = @type.constantize.find_by_id(params[:id])
    I18n.locale = @quizzable.locale_with_inheritance
    @in_quiz = params[:in_quiz] == 'true'
    @quiz_id = params[:quiz_id].to_i
  end

  def render_tag_title
    tag = Tag.find_by_id(params[:tag_id])
    @identified_tag = Tag.find_by_id(params[:identified_tag_id])
    @common_titles = tag.common_titles(@identified_tag)
  end
end
