# TagsController
class TagsController < ApplicationController
  before_action :set_tag, only: [:show, :edit, :destroy, :update, :inspect]
  before_action :check_for_consent
  before_action :check_permissions, only: [:update]
  authorize_resource

  def index
    @tags = Tag.order(:title)
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
    return if @errors.present?
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
    @modal = (params[:tag][:modal] == 'true')
    @tag = Tag.new
    check_permissions
    if @errors.present?
      render :update
      return
    end
    @tag = Tag.new(tag_params)
    @tag.save
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
  end

  private

  def set_tag
    @tag = Tag.find_by_id(params[:id])
    return if @tag.present?
    redirect_to :root, alert: 'Ein Begriff mit der angeforderten id existiert
                               nicht.'
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end

  def tag_params
    params.require(:tag).permit(:title, :related_tag_ids => [],
                                 :course_ids => [],
                                 :additional_lecture_ids => [],
                                 :disabled_lecture_ids => [])
  end

  def check_permissions
    @errors = {}
    return if current_user.admin?
    courses_errors
    additional_lectures_errors
    disabled_lectures_errors
  end

  def courses_errors
    errors = []
    removed_courses_ids = @tag.course_ids - tag_params[:course_ids].map(&:to_i)
    added_courses_ids = (tag_params[:course_ids].map(&:to_i) - [0]) -
                        @tag.course_ids
    edited_courses_ids = current_user.edited_courses.map(&:id)
    puts added_courses_ids
    unless removed_courses_ids.all? { |c| c.in?(edited_courses_ids) }
      errors.push('Für mindestens eines der Module, das Du entfernt hast, ' \
                  'hast Du keine Editorenrechte.')
    end
    unless added_courses_ids.all? { |c| c.in?(edited_courses_ids) }
      errors.push('Für mindestens eines der Module, das Du hinzugefügt hast, '\
                  'hast Du keine Editorenrechte.')
    end
    @errors.merge!({ courses: errors}) if errors.present?
    puts @errors
    puts 'Hi'
  end

  def additional_lectures_errors
    errors = []
    removed_additional_lectures_ids = @tag.additional_lecture_ids -
                                      tag_params[:additional_lecture_ids].map(&:to_i)
    added_additional_lectures_ids = (tag_params[:additional_lecture_ids].map(&:to_i) -
                                    [0]) - @tag.additional_lecture_ids
    edited_lectures_ids = current_user.edited_lectures_with_inheritance.map(&:id)
    unless removed_additional_lectures_ids.all? { |c| c.in?(edited_lectures_ids) }
      errors.push('Für mindestens eine der Vorlesungen, die Du entfernt ' \
                  'hast, hast Du keine Editorenrechte.')
    end
    unless added_additional_lectures_ids.all? { |c| c.in?(edited_lectures_ids) }
      errors.push('Für mindestens eine der Vorlesungen, die Du hinzugefügt ' \
                   'hast, hast Du keine Editorenrechte.')
    end
    @errors.merge!({ additional_lectures: errors}) if errors.present?
  end

  def disabled_lectures_errors
    errors = []
    removed_disabled_lectures_ids = @tag.disabled_lecture_ids -
                                      tag_params[:disabled_lecture_ids].map(&:to_i)
    added_disabled_lectures_ids = (tag_params[:disabled_lecture_ids].map(&:to_i) -
                                    [0]) - @tag.disabled_lecture_ids
    edited_lectures_ids = current_user.edited_lectures_with_inheritance.map(&:id)
    unless removed_disabled_lectures_ids.all? { |c| c.in?(edited_lectures_ids) }
      errors.push('Für mindestens eine der Vorlesungen, die Du entfernt hast, '\
                   'hast Du keine Editorenrechte.')
    end
    unless added_disabled_lectures_ids.all? { |c| c.in?(edited_lectures_ids) }
      errors.push('Für mindestens eine der Vorlesungen, die Du hinzugefügt ' \
                  'hast, hast Du keine Editorenrechte.')
    end
    @errors.merge!({ disabled_lectures: errors}) if errors.present?
  end
end
