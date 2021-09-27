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

  def render_medium_actions
    I18n.locale = current_user.locale
    @id = params[:id]
    @medium = Medium.find_by_id(@id)
    return unless @medium
    @tag_ids = @medium.tag_ids
  end

  def render_import_vertex
    @id = params[:id]
    quiz_id = params[:quiz_id]
    I18n.locale = Quiz.find_by_id(quiz_id)&.locale_with_inheritance
    @purpose = 'quiz'
    render :render_import_media
  end

  def render_import_media
    @id = params[:id]
    @purpose = 'import'
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
    render :cancel_import_media
  end

  def fill_reassign_modal
    @type = params[:type]
    @quizzable = @type.constantize.find_by_id(params[:id])
    I18n.locale = @quizzable.locale_with_inheritance
    @in_quiz = params[:in_quiz] == 'true'
    @quiz_id = params[:quiz_id].to_i
    @no_rights = params[:rights] == 'none'
  end

  def render_tag_title
    tag = Tag.find_by_id(params[:tag_id])
    @identified_tag = Tag.find_by_id(params[:identified_tag_id])
    @common_titles = tag.common_titles(@identified_tag)
  end

  def render_medium_tags
    @medium = Medium.find_by_id(params[:id])
    @tag_ids = @medium.tag_ids
  end

  def render_clickerizable_actions
    I18n.locale = current_user.locale
    @id = params[:id]
    @medium = Medium.find_by_id(@id)
    @question = Question.find_by_id(@id)
    @clicker = Clicker.find_by_id(params[:clicker])
  end

  def cancel_solution_edit
    @question = Question.find_by_id(params[:question_id])
  end

  def texify_solution
    result = params[:content][:question]
    @solution = Solution.from_hash(result[:solution_type],
                                   result[:solution_content])
  end

  def render_question_parameters
    @parameters = Question.parameters_from_text(params[:text])
    @id = params[:id]
  end

  def cancel_import_media
  end
end
