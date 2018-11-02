# TagsController
class TagsController < ApplicationController
  before_action :set_tag, only: [:show, :edit, :destroy, :update, :inspect]
  before_action :check_for_consent
  before_action :check_permissions, only: [:update]
  before_action :check_creation_permission, only: [:create]
  authorize_resource

  def index
    @tags = Tag.includes(:courses, :related_tags).order(:title)
    @tags_with_id = Tag.ids_titles_json
  end

  def show
    @related_tags = current_user.filter_tags(@tag.related_tags)
    @tags_in_neighbourhood = current_user.filter_tags(@tag
                                                        .tags_in_neighbourhood)
    @lectures = current_user.filter_lectures(@tag.lectures)
    @media = current_user.filter_media(@tag.media
                                           .where.not(sort: 'KeksQuestion'))
  end

  def inspect
  end

  def edit
  end

  def new
    @tag = Tag.new
  end

  def update
    return if @errors.present?
    @tag.update(tag_params)
    if @tag.valid?
      redirect_to edit_tag_path(@tag)
      return
    end
    @errors = @tag.errors
  end

  def create
    @section = Section.find_by_id(params[:tag][:section_id])
    if @errors.present?
      render :update
      return
    end
    @tag.update(tag_params)
    if @tag.valid?
      unless @modal
        redirect_to edit_tag_path(@tag)
        return
      end
    end
    @errors = @tag.errors
    render :update
  end

  def destroy
    @tag.destroy
    redirect_to tags_path
  end

  def modal
    @tag = Tag.new
    related_tag = Tag.find_by_id(params[:related_tag])
    @tag.related_tags << related_tag if related_tag.present?
    course = Course.find_by_id(params[:course])
    @tag.courses << course if course.present?
    section = Section.find_by_id(params[:section])
    @tag.sections << section if section.present?
    @from = params[:from]
  end

  private

  def set_tag
    @tag = Tag.find_by_id(params[:id])
    return if @tag.present?
    redirect_to :root, alert: 'Ein Begriff mit der angeforderten id existiert '\
                              'nicht.'
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end

  def tag_params
    params.require(:tag).permit(:title,
                                related_tag_ids: [],
                                course_ids: [],
                                section_ids: [])
  end

  def check_permissions
    @errors = {}
    return if current_user.admin?
    permission_errors
  end

  def permission_errors
    errors = []
    unless removed_courses.all? { |c| c.in?(current_user.edited_courses_with_inheritance) }
      errors.push(error_hash['remove_course'])
    end
    unless added_courses.all? { |c| c.in?(current_user.edited_courses_with_inheritance) }
      errors.push(error_hash['add_course'])
    end
    @errors[:courses] = errors if errors.present?
  end

  def check_creation_permission
    @modal = (params[:tag][:modal] == 'true')
    @tag = Tag.new
    check_permissions
  end

  def removed_courses
    @tag.courses - Course.where(id: tag_params[:course_ids])
  end

  def added_courses
    Course.where(id: tag_params[:course_ids]) - @tag.courses
  end

  def error_hash
    { 'remove_course' => 'Für mindestens eines der Module, das Du entfernt ' \
                         'hast, hast Du keine Editorenrechte.',
      'add_course' => 'Für mindestens eines der Module, das Du hinzugefügt ' \
                      'hast, hast Du keine Editorenrechte.' }
  end
end
