# TagsController
class TagsController < ApplicationController
  before_action :set_tag, only: [:show, :edit, :destroy, :update, :inspect,
                                 :display_cyto]
  before_action :set_related_tags_for_user, only: [:show, :display_cyto]
  before_action :set_related_tags, only: [:edit, :inspect]
  before_action :check_for_consent
  before_action :check_permissions, only: [:update]
  before_action :check_creation_permission, only: [:create]
  authorize_resource
  layout 'administration'

  def index
    @tags = Tag.includes(:courses, :related_tags)
    @tags_with_id = Tag.ids_titles_json
  end

  def show
    set_related_tags_for_user
    @lectures = current_user.filter_lectures(@tag.lectures)
    # first, filter the media according to the users subscription type
    media = current_user.filter_media(@tag.media
                                          .where.not(sort: ['Question',
                                                            'Remark']))
    # then, filter these according to their visibility for the user
    @media = current_user.filter_visible_media(media)
    render layout: 'application_no_sidebar'
  end

  def display_cyto
    set_related_tags_for_user
    render layout: 'cytoscape'
  end

  def inspect
    set_related_tags
  end

  def edit
    set_related_tags
    # build notions for missing locales
    (I18n.available_locales.map(&:to_s) - @tag.locales).each do |l|
      @tag.notions.new(locale: l)
    end
  end

  def new
    @tag = Tag.new
    set_notions
  end

  def update
    # first, check if errors from check_permission callback are present
    return if @errors.present?
    @tag.update(tag_params)
    if @tag.valid?
      # make sure the tag is touched even if only some relations have been
      # modified (important for caching)
      @tag.touch
      redirect_to edit_tag_path(@tag)
      return
    end
    @errors = @tag.errors
    pp @errors
  end

  def create
    # first, check if errors from creation_permission callback are present
    @section = Section.find_by_id(params[:tag][:section_id])
    if @errors.present?
      render :update
      return
    end
    @tag.update(tag_params)
    # append newly created tag at the end of the *ordered* tags for
    # the relevant sections
    update_sections if @tag.valid? && tag_params[:section_ids]
    if @tag.valid? && !@modal
      redirect_to edit_tag_path(@tag)
      return
    end
    @errors = @tag.errors
    render :update
  end

  def destroy
    @tag.destroy
    redirect_to tags_path
  end

  # prepare new tag instance for modal
  def modal
    set_up_tag
    add_course
    add_section
    add_medium
    @from = params[:from]
  end

  private

  def set_tag
    @tag = Tag.find_by_id(params[:id])
    return if @tag.present?
    redirect_to :root, alert: 'Ein Begriff mit der angeforderten id existiert '\
                              'nicht.'
  end

  # set up cytoscape graph data for neighbourhood subgraph of @tag,
  # using only neighbourhood tags that are allowd by the user's
  # profile settings
  def set_related_tags_for_user
    user_tags = current_user.visible_tags
    @related_tags = @tag.related_tags & user_tags
    @tags_in_neighbourhood = Tag.related_tags(@related_tags) & user_tags
    @tags = [@tag] + @related_tags + @tags_in_neighbourhood
    @graph_elements = Tag.to_cytoscape(@tags, @tag)
  end

  # set up cytoscape graph data for neighbourhood subgraph of @tag,
  def set_related_tags
    related_tags = @tag.related_tags
    tags_in_neighbourhood = Tag.related_tags(related_tags)
    @graph_elements = Tag.to_cytoscape([@tag] + related_tags +
                                       tags_in_neighbourhood, @tag)
  end

  def set_up_tag
    @tag = Tag.new
    set_notions
    related_tag = Tag.find_by_id(params[:related_tag])
    @tag.related_tags << related_tag if related_tag.present?
  end

  def add_course
    course = Course.find_by_id(params[:course])
    @tag.courses << course if course.present?
  end

  def add_section
    section = Section.find_by_id(params[:section])
    @tag.sections << section if section.present?
  end

  def add_medium
    medium = Medium.find_by_id(params[:medium])
    @tag.media << medium if medium.present?
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end

  def tag_params
    params.require(:tag).permit(related_tag_ids: [],
                                notions_attributes: [:title, :locale, :id,
                                  :_destroy],
                                course_ids: [],
                                section_ids: [],
                                media_ids: [])
  end

  def check_permissions
    @errors = {}
    return if current_user.admin?
    # of current user is not an admin, he can add/remove courses only
    # as course editor with inheritance/course_editor
    permission_errors
  end

  def permission_errors
    errors = []
    unless removed_courses.all? { |c| c.removable_by?(current_user) }
      errors.push(error_hash['remove_course'])
    end
    unless added_courses.all? { |c| c.addable_by?(current_user) }
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

  def update_sections
    sections = Section.where(id: tag_params[:section_ids])
    sections.each do |s|
      s.update(tags_order: s.tags_order.to_a + [@tag.id])
    end
  end

  def set_notions
    @tag.notions.new(locale: I18n.locale)
    (I18n.available_locales - [I18n.locale]).each do |l|
      @tag.notions.new(locale: l)
    end
  end

  def error_hash
    { 'remove_course' => 'Für mindestens eines der Module, das Du entfernt ' \
                         'hast, hast Du keine Editorenrechte für das ' \
                         'Entfernen von Tags.',
      'add_course' => 'Für mindestens eines der Module, das Du hinzugefügt ' \
                      'hast, hast Du keine Editorenrechte für das Hinzufügen ' \
                      'von Tags.' }
  end
end
