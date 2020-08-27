# CoursesController
class CoursesController < ApplicationController
  before_action :check_for_course, only: [:show]
  before_action :set_course, only: [:show, :display, :take_random_quiz,
                                    :show_random_quizzes,
                                    :render_question_counter,
                                    :add_forum, :lock_forum, :unlock_forum,
                                    :destroy_forum]
  before_action :set_course_admin, only: [:edit, :update, :destroy, :inspect]
  before_action :check_if_enough_questions, only: [:show_random_quizzes,
                                                   :take_random_quiz]
  before_action :check_for_consent
  authorize_resource
  layout 'administration'

  def edit
    I18n.locale = @course.locale || I18n.default_locale
    cookies[:edited_course] = params[:id]
  end

  def update
    I18n.locale = @course.locale || I18n.default_locale
    @course.update(course_params)
    @errors = @course.errors
  end

  def create
    @course = Course.new(course_params)
    @course.save
    if @course.valid?
      # set organizational_concept to default
      set_organizational_defaults
      redirect_to administration_path
      return
    end
    @errors = @course.errors
  end

  def show
    cookies[:current_course] = @course.id
    # deactivate http caching for the moment
    # "refused to execute script because its mime type is not executable
    #  error in Chrome"...
    if stale?(etag: @course,
              last_modified: [current_user.updated_at, @course.updated_at,
                              Time.parse(ENV['RAILS_CACHE_ID']),
                              Thredded::UserDetail.find_by(user_id: current_user.id)
                                                  &.last_seen_at || current_user.updated_at,
                              @course&.forum&.updated_at || current_user.updated_at].max)
      cookies[:current_lecture] = nil
      I18n.locale = @course.locale || I18n.default_locale
      render layout: 'application'
      return
    end
  end

  def inspect
    I18n.locale = @course.locale || I18n.default_locale
  end

  def destroy
    @course.destroy
    # destroy all notifications related to this course
    destroy_notifications
    redirect_to administration_path
  end

  def display
    I18n.locale = @course.locale || I18n.default_locale
    render layout: 'application'
  end

  def show_random_quizzes
    lecture = Lecture.find_by_id(params[:lecture_id])
    I18n.locale = if lecture
                    lecture.locale_with_inheritance
                  else
                    @course.locale
                  end
    render layout: 'application'
  end

  def take_random_quiz
    tags = Tag.where(id: random_quiz_params[:search_tag_ids])
    random_quiz = @course.create_random_quiz!(tags, random_quiz_params[:random_quiz_count].to_i)
    redirect_to take_quiz_path(random_quiz)
  end

  def render_question_counter
    tags = Tag.where(id: tag_params[:tag_ids])
    @count = @course.question_count(tags)
  end

  # add forum for this course
  def add_forum
    unless @course.forum?
      forum = Thredded::Messageboard.new(name: @course.forum_title)
      forum.save
      @course.update(forum_id: forum.id) if forum.valid?
    end
    redirect_to edit_course_path(@course)
  end

  # lock forum for this course
  def lock_forum
    @course.forum.update(locked: true) if @course.forum?
    @course.touch
    redirect_to edit_course_path(@course)
  end

  # unlock forum for this course
  def unlock_forum
    @course.forum.update(locked: false) if @course.forum?
    @course.touch
    redirect_to edit_course_path(@course)
  end

  # destroy forum for this lecture
  def destroy_forum
    @course.forum.destroy if @course.forum?
    @course.update(forum_id: nil)
    redirect_to edit_course_path(@course)
  end

  private

  def check_for_course
    return if Course.exists?(params[:id])
    redirect_to :root, alert: I18n.t('controllers.no_course')
  end

  def set_course
    @course = Course.find_by_id(params[:id])
    return if @course.present?
    redirect_to :root, alert: I18n.t('controllers.no_course')
  end

  def set_course_admin
    @course = Course.find_by_id(params[:id])
    return if @course.present?
    redirect_to administration_path
  end

  def course_params
    params.require(:course).permit(:title, :short_title, :organizational,
                                   :organizational_concept, :locale,
                                   :term_independent,
                                   tag_ids: [],
                                   preceding_course_ids: [],
                                   editor_ids: [],
                                   division_ids: [])
  end

  def tag_params
    params.permit(:count, tag_ids: [])
  end

  def random_quiz_params
    params.require(:quiz).permit(:random_quiz_count,
                                 search_tag_ids: [])
  end

  # destroy all notifications related to this course
  def destroy_notifications
    Notification.where(notifiable_id: @course.id, notifiable_type: 'Course')
                .delete_all
  end

  # fill organizational_concept with default view
  def set_organizational_defaults
    @course.update(organizational_concept:
                     render_to_string(partial: 'courses/' \
                                               'organizational_default',
                                      formats: :html,
                                      layout: false))
  end

  def check_if_enough_questions
    return if @course.enough_questions?
    redirect_to :root, alert: I18n.t('controllers.no_test')
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end
end
