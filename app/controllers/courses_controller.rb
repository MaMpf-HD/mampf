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
    if @course.save
      # set organizational_concept to default
      set_organizational_defaults

      flash.now[:notice] = I18n.t("controllers.created_course_success",
                                  course: @course.title,
                                  editors: @course.editors.map(&:name)
                                                          .join(", "))
      render turbo_stream: [
        stream_flash,
        turbo_stream.update("courses",
                            partial: "administration/index/courses_card",
                            locals: { courses: current_user.edited_courses
                                                      .natural_sort_by(&:title) })
      ]

    end
    @errors = @course.errors
    return if @errors.empty? || !request.format.turbo_stream?

    render_course_errors_turbo_stream(
      title_input_id: "new_course_title",
      title_error_id: "new-course-title-error",
      short_title_input_id: "new_course_short_title",
      short_title_error_id: "new-course-short-title-error"
    )
  end

  def update
    I18n.locale = @course.locale || I18n.default_locale
    old_image_data = @course.image_data
    @course.update(course_params)
    @errors = @course.errors
    if @errors.present?
      if request.format.turbo_stream?
        render_course_errors_turbo_stream(
          title_input_id: "course_title",
          title_error_id: "course-title-error",
          short_title_input_id: "course_short_title",
          short_title_error_id: "course-short-title-error"
        )
      end
      return
    end

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

    @pagy, @courses = Search::Searchers::ControllerSearcher.search(
      controller: self,
      model_class: Course,
      configurator_class: Search::Configurators::CourseSearchConfigurator,
      options: { default_per_page: 20 }
    )

    respond_to do |format|
      format.js
      format.html do
        redirect_to :root, alert: I18n.t("controllers.search_only_js")
      end
    end
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
                        { tag_ids: [], preceding_course_ids: [], division_ids: [] }]
      allowed_params.push(editor_ids: []) if current_user.admin?
      params.expect(course: allowed_params)
    end

    def tag_params
      params.permit(:count, tag_ids: [])
    end

    def search_params
      params.expect(search: [:all_editors, :all_programs, :fulltext,
                             :term_independent, :per,
                             { editor_ids: [],
                               program_ids: [] }])
    end

    def random_quiz_params
      params.expect(quiz: [:random_quiz_count,
                           { search_course_tag_ids: [] }])
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

    def render_course_errors_turbo_stream(title_input_id:, title_error_id:, short_title_input_id:,
                                          short_title_error_id:)
      render turbo_stream: [
        turbo_stream.replace(title_input_id,
                             view_context.text_field_tag(
                               "course[title]",
                               @course.title,
                               id: title_input_id,
                               class: "form-control#{" is-invalid" if @errors[:title].present?}"
                             )),
        turbo_stream.update(title_error_id,
                            @errors[:title].to_a.join(", ")),
        turbo_stream.replace(short_title_input_id,
                             view_context.text_field_tag(
                               "course[short_title]",
                               @course.short_title,
                               id: short_title_input_id,
                               class: "form-control#{if @errors[:short_title].present?
                                                       " is-invalid"
                                                     end}"
                             )),
        turbo_stream.update(short_title_error_id,
                            @errors[:short_title].to_a.join(", "))
      ], status: :unprocessable_content
    end
end
