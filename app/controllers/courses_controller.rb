# CoursesController
class CoursesController < ApplicationController
  before_action :set_course, only: [:take_random_quiz, :render_question_counter]
  before_action :set_course_admin, only: [:edit, :update, :destroy]
  before_action :check_if_enough_questions, only: [:take_random_quiz]
  before_action :check_for_consent
  authorize_resource except: [:create, :search]
  layout "administration"

  def current_ability
    @current_ability ||= CourseAbility.new(current_user)
  end

  def edit
    I18n.locale = @course.locale || I18n.default_locale
  end

  def create
    @course = Course.new(course_params)
    authorize! :create, @course
    @course.save
    if @course.valid?
      # set organizational_concept to default
      set_organizational_defaults
      redirect_to administration_path,
                  notice: I18n.t("controllers.created_course_success",
                                 course: @course.title,
                                 editors: @course.editors.map(&:name)
                                                         .join(", "))
      return
    end
    @errors = @course.errors
  end

  def update
    I18n.locale = @course.locale || I18n.default_locale
    old_image_data = @course.image_data
    @course.update(course_params)
    @errors = @course.errors
    return unless @errors.empty?

    @course.update(image: nil) if params[:course][:detach_image] == "true"
    changed_image = @course.image_data != old_image_data
    if @course.image.present? && changed_image
      @course.image_derivatives!
      @course.save
    end
    @errors = @course.errors
  end

  def destroy
    @course.destroy
    # destroy all notifications related to this course
    destroy_notifications
    redirect_to administration_path
  end

  def take_random_quiz
    tags = Tag.where(id: random_quiz_params[:search_course_tag_ids])
    random_quiz = @course.create_random_quiz!(tags,
                                              random_quiz_params[:random_quiz_count].to_i)
    redirect_to take_quiz_path(random_quiz)
  end

  def render_question_counter
    tags = Tag.where(id: tag_params[:tag_ids])
    @count = @course.question_count(tags)
  end

  def search
    authorize! :search, Course.new
    search = Course.search_by(search_params, params[:page])
    search.execute
    results = search.results
    @total = search.total
    @courses = Kaminari.paginate_array(results, total_count: @total)
                       .page(params[:page]).per(search_params[:per])
  end

  private

    def set_course
      @course = Course.find_by(id: params[:id])
      return if @course.present?

      redirect_to :root, alert: I18n.t("controllers.no_course")
    end

    def set_course_admin
      @course = Course.find_by(id: params[:id])
      return if @course.present?

      redirect_to administration_path
    end

    def course_params
      allowed_params = [:title, :short_title, :organizational,
                        :organizational_concept, :locale,
                        :term_independent, :image,
                        { tag_ids: [],
                          preceding_course_ids: [],
                          division_ids: [] }]
      allowed_params.push({ editor_ids: [] }) if current_user.admin?
      params.require(:course).permit(allowed_params)
    end

    def tag_params
      params.permit(:count, tag_ids: [])
    end

    def search_params
      params.require(:search).permit(:all_editors, :all_programs, :fulltext,
                                     :term_independent, :per,
                                     editor_ids: [],
                                     program_ids: [])
    end

    def random_quiz_params
      params.require(:quiz).permit(:random_quiz_count,
                                   search_course_tag_ids: [])
    end

    # destroy all notifications related to this course
    def destroy_notifications
      Notification.where(notifiable_id: @course.id, notifiable_type: "Course")
                  .delete_all
    end

    # fill organizational_concept with default view
    def set_organizational_defaults
      @course.update(organizational_concept:
                       render_to_string(partial: "courses/" \
                                                 "organizational_default",
                                        formats: :html,
                                        layout: false))
    end

    def check_if_enough_questions
      return if @course.enough_questions?

      redirect_to :root, alert: I18n.t("controllers.no_test")
    end

    def check_for_consent
      redirect_to consent_profile_path unless current_user.consents
    end
end
