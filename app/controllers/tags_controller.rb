# TagsController
class TagsController < ApplicationController
  before_action :set_tag, only: [:show, :edit, :destroy, :update,
                                 :display_cyto, :identify, :take_random_quiz]
  before_action :set_related_tags_for_user, only: [:show, :display_cyto]
  before_action :set_related_tags, only: [:edit]
  before_action :check_for_consent
  before_action :check_permissions, only: [:update]
  before_action :check_creation_permission, only: [:create]
  authorize_resource except: [:new, :modal, :search, :postprocess,
                              :render_tag_title]
  layout "administration"

  def current_ability
    @current_ability ||= TagAbility.new(current_user)
  end

  def show
    I18n.locale = params[:locale] if params[:locale].in?(I18n.available_locales.map(&:to_s))
    set_related_tags_for_user
    @lectures = current_user.filter_lectures(@tag.lectures)
    # first, filter the media according to the users subscription type
    media = current_user.filter_media(@tag.media
                                          .where.not(sort: ["Question",
                                                            "Remark"]))
    # then, filter these according to their visibility for the user
    @media = current_user.filter_visible_media(media)
    @questions = @tag.visible_questions(current_user)
    # consider items in manuscripts that are corresponding to tags
    manuscripts = current_user.filter_media(Medium.where(sort: "Script"))
    @references = Item.where(medium: manuscripts,
                             description: @tag.notions.pluck(:title) +
                                            @tag.aliases.pluck(:title))
                      .where.not(pdf_destination: [nil, ""])
    @realizations = @tag.realizations
    render layout: "application_no_sidebar"
  end

  def display_cyto
    set_related_tags_for_user
    render layout: "cytoscape"
  end

  def new
    @tag = Tag.new
    authorize! :new, @tag
    set_notions
    @tag.aliases.new(locale: I18n.locale)
  end

  def edit
    # build notions for missing locales
    (I18n.available_locales.map(&:to_s) - @tag.locales).each do |l|
      @tag.notions.new(locale: l)
    end
    @tag.aliases.new(locale: I18n.locale)
  end

  def create
    # first, check if errors from creation_permission callback are present
    @section = Section.find_by(id: params[:tag][:section_id])
    if @errors.present?
      render :update
      return
    end
    @tag.update(tag_params)
    if @tag.valid? && !@modal
      redirect_to edit_tag_path(@tag)
      return
    end
    @errors = @tag.errors
    render :update
  end

  def update
    # first, check if errors from check_permission callback are present
    return if @errors.present?

    @tag.update(tag_params)
    if @tag.valid?
      @tag.update(realizations: realization_params)
      # make sure the tag is touched even if only some relations have been
      # modified (important for caching)
      @tag.touch
      redirect_to edit_tag_path(@tag)
      return
    end
    @errors = @tag.errors
  end

  def destroy
    @tag.destroy
    redirect_to administration_path
  end

  # prepare new tag instance for modal
  def modal
    set_up_tag
    authorize! :modal, @tag
    @tag.aliases.new(locale: I18n.locale)
    add_course
    add_section
    add_medium
    add_lesson
    add_talk
    @from = params[:from]
    @locale = locale
  end

  def identify
    @identified_tag = Tag.find_by(id: params[:tag][:identified_tag_id])
    @tag.identify_with!(@identified_tag)
    @identified_tag.destroy
    @tag.update(tag_params)
    @errors = @tag.errors
  end

  def fill_tag_select
    I18n.locale = params[:locale] if params[:locale].in?(I18n.available_locales.map(&:to_s))
    if params[:q]
      result = Tag.select_with_substring(params[:q])
      render json: result
      return
    end
    result = Tag.select_by_title_cached
    render json: result
  end

  def fill_course_tags
    course = Course.find_by(id: params[:course_id])
    result = course&.select_question_tags_by_title
    render json: result
  end

  def search
    authorize! :search, Tag.new
    per_page = search_params[:per] || 10
    search = Sunspot.new_search(Tag)
    search.build do
      fulltext search_params[:title]
    end
    course_ids = if search_params[:all_courses] == "1"
      []
    elsif search_params[:course_ids] != [""]
      search_params[:course_ids]
    end
    search.build do
      with(:course_ids, course_ids)
      paginate page: params[:page], per_page: per_page
    end
    search.execute
    results = search.results
    @total = search.total
    @tags = Kaminari.paginate_array(results, total_count: @total)
                    .page(params[:page]).per(per_page)
  end

  def take_random_quiz
    random_quiz = @tag.create_random_quiz!(current_user)
    redirect_to take_quiz_path(random_quiz)
  end

  def postprocess
    authorize! :postprocess, Tag.new
    @tags_hash = params[:tags]
    @tags_hash.each do |t, section_data|
      tag = Tag.find_by(id: t)
      next unless tag

      section_data.each do |s, v|
        next if v.to_i.zero?

        section = Section.find(s)
        next unless section

        section.tags << tag unless tag.in?(section.tags)
      end
    end
    if params["from"] == "Lesson"
      redirect_to edit_lesson_path(Lesson.find_by(id: params[:id]))
      return
    end
    redirect_to edit_medium_path(Medium.find_by(id: params[:id]))
  end

  def render_tag_title
    authorize! :render_tag_title, Tag.new
    tag = Tag.find_by(id: params[:tag_id])
    @identified_tag = Tag.find_by(id: params[:identified_tag_id])
    @common_titles = tag.common_titles(@identified_tag)
  end

  private

    def set_tag
      @tag = Tag.find_by(id: params[:id])
      return if @tag.present?

      redirect_to :root, alert: I18n.t("controllers.no_tag")
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
      overrule_subscription_type = selection if selection.in?([1, 2, 3])
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
      related_tag = Tag.find_by(id: params[:related_tag])
      @tag.related_tags << related_tag if related_tag.present?
    end

    def add_course
      course = Course.find_by(id: params[:course])
      @tag.courses << course if course.present?
    end

    def add_section
      section = Section.find_by(id: params[:section])
      return unless section

      @tag.sections << section
      I18n.locale = section.lecture.locale || current_user.locale
    end

    def add_medium
      medium = Medium.find_by(id: params[:medium])
      return unless medium

      I18n.locale = medium.locale_with_inheritance || current_user.locale
      @tag.media << medium
    end

    def add_lesson
      lesson = Lesson.find_by(id: params[:lesson])
      return unless lesson

      @tag.lessons << lesson
      I18n.locale = lesson.lecture.locale || current_user.locale
    end

    def add_talk
      talk = Talk.find_by(id: params[:talk])
      return unless talk

      @tag.talks << talk
      I18n.locale = talk.lecture.locale || current_user.locale
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
                                  talk_ids: [],
                                  media_ids: [])
    end

    def realization_params
      (params.require(:tag).permit(realizations: [])[:realizations] - [""])
        .map { |r| r.split("-") }
        .map { |x| [x.first, x.second.to_i] }
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
        errors.push(error_hash["remove_course"])
      end
      unless added_courses.all? { |c| c.addable_by?(current_user) }
        errors.push(error_hash["add_course"])
      end
      @errors[:courses] = errors if errors.present?
    end

    def check_creation_permission
      @modal = (params[:tag][:modal] == "true")
      @tag = Tag.new
      check_permissions
    end

    def removed_courses
      @tag.courses - Course.where(id: tag_params[:course_ids])
    end

    def added_courses
      Course.where(id: tag_params[:course_ids]) - @tag.courses
    end

    def set_notions
      @tag.notions.new(locale: I18n.locale)
      (I18n.available_locales - [I18n.locale]).each do |l|
        @tag.notions.new(locale: l)
      end
    end

    def locale
      locale = case params[:from]
               when "course"
                 @tag.courses&.first&.locale
               when "medium"
                 @tag.media&.first&.locale_with_inheritance
               when "section"
                 @tag.sections&.first&.lecture&.locale_with_inheritance
      end
      locale || current_user.locale
    end

    def error_hash
      { "remove_course" => I18n.t("controllers.no_removal_rights"),
        "add_course" => I18n.t("controllers.no_adding_rights") }
    end

    def search_params
      params.require(:search).permit(:title, :all_courses, :per, course_ids: [])
    end
end
