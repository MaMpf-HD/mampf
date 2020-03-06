# TagsController
class TagsController < ApplicationController
  before_action :set_tag, only: [:show, :edit, :destroy, :update, :inspect,
                                 :display_cyto, :identify, :take_random_quiz]
  before_action :set_related_tags_for_user, only: [:show, :display_cyto]
  before_action :set_related_tags, only: [:edit, :inspect]
  before_action :check_for_consent
  before_action :check_permissions, only: [:update]
  before_action :check_creation_permission, only: [:create]
  authorize_resource
  layout 'administration'

  def index
    I18n.locale = current_user.locale
  end

  def show
    if params[:locale].in?(I18n.available_locales.map(&:to_s))
      I18n.locale = params[:locale]
    end
    set_related_tags_for_user
    @lectures = current_user.filter_lectures(@tag.lectures)
    # first, filter the media according to the users subscription type
    media = current_user.filter_media(@tag.media
                                          .where.not(sort: ['Question',
                                                            'Remark']))
    # then, filter these according to their visibility for the user
    @media = current_user.filter_visible_media(media)
    @questions = @tag.visible_questions(current_user)
    # consider items in manuscripts that are corresponding to tags
    manuscripts = current_user.filter_media(Medium.where(sort: 'Script'))
    @references = Item.where(medium: manuscripts,
                             description: @tag.notions.pluck(:title) +
                                            @tag.aliases.pluck(:title))
                      .where.not(pdf_destination: [nil, ''])
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
    @tag.aliases.new(locale: I18n.locale)
  end

  def new
    @tag = Tag.new
    set_notions
    @tag.aliases.new(locale: I18n.locale)
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
    @tag.aliases.new(locale: I18n.locale)
    add_course
    add_section
    add_medium
    add_lesson
    @from = params[:from]
    @locale = locale
  end

  def identify
    @identified_tag = Tag.find_by_id(params[:tag][:identified_tag_id])
    @tag.identify_with!(@identified_tag)
    @identified_tag.destroy
    @tag.update(tag_params)
    @errors = @tag.errors
  end

  def fill_tag_select
    if params[:locale].in?(I18n.available_locales.map(&:to_s))
      I18n.locale = params[:locale]
    end
    result = Tag.select_by_title_cached
    render json: result
  end

  def fill_course_tags
    course = Course.find_by_id(params[:course_id])
    result = course&.select_question_tags_by_title
    render json: result
  end

  def search
    search = Sunspot.new_search(Tag)
    search.build do
      fulltext search_params[:title]
    end
    if search_params[:course_ids] == ['']
      search.build do
        with(:course_ids, nil)
      end
    else
      search.build do
        with(:course_ids, search_params[:course_ids])
      end
    end
    search.build do
      paginate page: params[:page], per_page: 10
    end
    search.execute
    results = search.results
    @total = search.total
    @tags = Kaminari.paginate_array(results, total_count: @total)
                    .page(params[:page]).per(10)
  end

  def take_random_quiz
    random_quiz = @tag.create_random_quiz!(current_user)
    redirect_to take_quiz_path(random_quiz)
  end

  def postprocess
    @tags_hash = params[:tags]
    @tags_hash.each do |t, section_data|
      tag = Tag.find_by_id(t)
      next unless tag
      section_data.each do |s, v|
        next if v.to_i == 0
        section = Section.find(s)
        next unless section
        if !tag.in?(section.tags)
          section.tags << tag
          section.update(tags_order: section.tags_order.push(tag.id))
        end
      end
    end
    if params['from'] == 'Lesson'
      redirect_to edit_lesson_path(Lesson.find_by_id(params[:id]))
      return
    end
    redirect_to edit_medium_path(Medium.find_by_id(params[:id]))
  end

  private

  def set_tag
    @tag = Tag.find_by_id(params[:id])
    return if @tag.present?
    redirect_to :root, alert: I18n.t('controllers.no_tag')
  end

  # set up cytoscape graph data for neighbourhood subgraph of @tag,
  # using only neighbourhood tags that are allowd by the user's
  # profile settings, depending on the parameters (selection/depth) that were
  # specified by the user)
  def set_related_tags_for_user
    @depth = 2
    depth_param = params[:depth].to_i
    @depth = depth_param if depth_param.in?([1, 2])
    overrule_subscription_type = false
    selection = params[:selection].to_i
    if selection.in?([1, 2, 3])
      overrule_subscription_type = selection
    end
    @selection_type = if overrule_subscription_type
                         selection
                       else
                         current_user.subscription_type
                       end
    user_tags = current_user.visible_tags(overrule_subscription_type: overrule_subscription_type)
    @related_tags = @tag.related_tags & user_tags
    @tags_in_neighbourhood = if @depth == 2
                               Tag.related_tags(@related_tags) & user_tags
                             else
                               []
                             end
    @tags = [@tag] + @related_tags + @tags_in_neighbourhood
    @graph_elements = Tag.to_cytoscape(@tags, @tag,
                                       highlight_related_tags: @depth == 2)
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
    if section
      @tag.sections << section
      I18n.locale = section.lecture.locale || current_user.locale
    end
  end

  def add_medium
    medium = Medium.find_by_id(params[:medium])
    if medium
        I18n.locale = medium.locale_with_inheritance || current_user.locale
        @tag.media << medium
    end
  end

  def add_lesson
    lesson = Lesson.find_by_id(params[:lesson])
    if lesson
      @tag.lessons << lesson
      I18n.locale = lesson.lecture.locale || current_user.locale
    end
  end

  def check_for_consent
    redirect_to consent_profile_path unless current_user.consents
  end

  def tag_params
    params.require(:tag).permit(related_tag_ids: [],
                                notions_attributes: [:title, :locale, :id,
                                  :_destroy],
                                aliases_attributes: [:title, :locale, :id,
                                  :_destroy],
                                course_ids: [],
                                section_ids: [],
                                lesson_ids: [],
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

  def locale
    locale = if params[:from] == 'course'
               @tag.courses&.first&.locale
             elsif params[:from] == 'medium'
               @tag.media&.first&.locale_with_inheritance
             elsif params[:from] == 'section'
               @tag.sections&.first&.lecture&.locale_with_inheritance
             end
    locale || current_user.locale
  end

  def error_hash
    { 'remove_course' => I18n.t('controllers.no_removal_rights'),
      'add_course' => I18n.t('controllers.no_adding_rights') }
  end

  def search_params
    params.require(:search).permit(:title, course_ids: [])
  end

end
