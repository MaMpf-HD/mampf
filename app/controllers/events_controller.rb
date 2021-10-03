# Events controller
# Deals with all AJAX actions in Quizzes
class EventsController < ApplicationController
#  authorize_resource class: false
#  to do: authorization needs to be done manually

  def current_ability
    @current_ability ||= EventAbility.new(current_user)
  end

  def fill_quizzable_area
    @id = params[:id]
    @type = params[:type]
    @vertex_id = params[:vertex]
    @quizzable = @type.constantize.find_by_id(@id)
    I18n.locale = @quizzable.locale_with_inheritance
  end

  def fill_quizzable_preview
    @id = params[:id]
    @type = params[:type]
    @quizzable = @type.constantize.find_by_id(@id)
    I18n.locale = @quizzable.locale_with_inheritance
  end

  def render_vertex_quizzable
    @quiz = Quiz.find_by_id(params[:quiz_id])
    @vertex_id = params[:id].to_i
    @quizzable = @quiz.quizzable(@vertex_id)
  end

  def fill_reassign_modal
    @type = params[:type]
    @quizzable = @type.constantize.find_by_id(params[:id])
    I18n.locale = @quizzable.locale_with_inheritance
    @in_quiz = params[:in_quiz] == 'true'
    @quiz_id = params[:quiz_id].to_i
    @no_rights = params[:rights] == 'none'
  end
end
