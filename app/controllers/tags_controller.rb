# TagsController
class TagsController < ApplicationController
  before_action :set_tag, only: [:show, :edit, :destroy, :update, :inspect]
  before_action :check_for_consent
  before_action :check_permissions, only: [:update]
  before_action :check_creation_permission, only: [:create]
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
    params.require(:tag).permit(:title,
                                related_tag_ids: [],
                                course_ids: [],
                                additional_lecture_ids: [],
                                disabled_lecture_ids: [])
  end

  def check_additional_lecture_compatibility
    courses = Course.where(id: tag_params[:course_ids])
    lectures = courses.collect(&:lectures).flatten
    additional = Lecture.where(id: tag_params[:additional_lecture_ids]).to_a
    return if (additional & lectures).empty?
    @errors[:additional_lectures] = [error_hash['incompatible_addition']]
  end

  def check_disabled_lecture_compatibility
    courses = Course.where(id: tag_params[:course_ids])
    lectures = courses.collect(&:lectures).flatten
    disabled = Lecture.where(id: tag_params[:disabled_lecture_ids]).to_a
    return if disabled.empty? || (disabled & lectures).present?
    @errors[:disabled_lectures] = [error_hash['incompatible_disabling']]
  end

  def check_permissions
    @errors = {}
    check_additional_lecture_compatibility
    check_disabled_lecture_compatibility
    puts 'Hi'
    puts @errors
    return if @errors.present?
    return if current_user.admin?
    permission_errors('course')
    permission_errors('additional_lecture')
    permission_errors('disabled_lecture')
  end

  def permission_errors(kind)
    sort = kind + '_ids'
    species = kind == 'course' ? 'course' : 'lecture'
    errors = []
    unless removed_ids(sort).all? { |c| c.in?(edited_ids(species)) }
      errors.push(error_hash['remove_' + species])
    end
    unless added_ids(sort).all? { |c| c.in?(edited_ids(species)) }
      errors.push(error_hash['add_' + species])
    end
    @errors[(kind + 's').to_sym] = errors if errors.present?
  end

  def check_creation_permission
    @modal = (params[:tag][:modal] == 'true')
    @tag = Tag.new
    check_permissions
  end

  def removed_ids(sort)
    @tag.send(sort) - tag_params[sort].map(&:to_i)
  end

  def edited_ids(species)
    current_user.send('edited_' + species + 's_with_inheritance').map(&:id)
  end

  def added_ids(sort)
    (tag_params[sort].map(&:to_i) - [0]) - @tag.send(sort)
  end

  def error_hash
    { 'remove_lecture' => 'Für mindestens eine der Vorlesungen, die Du ' \
                          'entfernt hast, hast Du keine Editorenrechte.',
      'add_lecture' => 'Für mindestens eine der Vorlesungen, die Du ' \
                       'hinzugefügt hast, hast Du keine Editorenrechte.',
      'remove_course' => 'Für mindestens eines der Module, das Du entfernt ' \
                         'hast, hast Du keine Editorenrechte.',
      'add_course' => 'Für mindestens eines der Module, das Du hinzugefügt ' \
                      'hast, hast Du keine Editorenrechte.',
      'incompatible_addition' => 'Eine der zusätzlichen Vorlesungen ' \
                                 'gehört zu einem Modul, was zu diesem ' \
                                 'Tag aktiviert ist.',
      'incompatible_disabling' => 'Eine der deaktivierten Vorlesungen ' \
                                  'gehört nicht zu einem Modul, was zu ' \
                                  'diesem Tag aktiviert ist.' }
  end
end
