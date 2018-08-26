# TagsController
class TagsController < ApplicationController
  before_action :set_tag, only: [:show, :edit, :destroy, :update]
  before_action :check_for_consent
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

  def edit
  end

  def new
  end

  def update
    puts tag_params
    removed_tags = @tag.related_tag_ids - tag_params[:related_tag_ids].map(&:to_i)
    added_tags = (tag_params[:related_tag_ids].map(&:to_i) - [0]) - @tag.related_tag_ids
    puts removed_tags
    if !current_user.admin?
      if !(@tag.course_ids & current_user.edited_course_ids).present?
        if removed_tags.any? { |t| (Tag.find_by_id(t).course_ids & current_user.edited_course_ids).empty? }
          @errors = { related_tags: ['Das Tag gehört zu Kursen, für die Du kein Editor bist, und mindestens eines der entfernten Tags gehört zu Kursen, für die Du kein Editor bist.'] }
          return
        end
        if added_tags.any? { |t| (Tag.find_by_id(t).course_ids & current_user.edited_course_ids).empty? }
          @errors = { related_tags: ['Das Tag gehört zu Kursen, für die Du kein Editor bist, und mindestens eines der hinzugefügten Tags gehört zu Kursen, für die Du kein Editor bist.'] }
          return
        end
      end
    end
    removed_courses = @tag.course_ids - tag_params[:course_ids].map(&:to_i)
    unless current_user.admin? || removed_courses.all? { |c| c.in?(current_user.edited_courses.map(&:id)) }
      @errors = { courses: ['Du hast nicht die nötigen Rechte dafür.'] }
      return
    end
    added_courses = (tag_params[:course_ids].map(&:to_i) - [0]) - @tag.course_ids
    unless current_user.admin? || added_courses.all? { |c| c.in?(current_user.edited_courses.map(&:id)) }
      @errors = { courses: ['Du hast nicht die nötigen Rechte dafür.'] }
      return
    end
    removed_additional_lectures = @tag.additional_lecture_ids - tag_params[:additional_lecture_ids].map(&:to_i)
    unless current_user.admin? || removed_additional_lectures.all? { |c| c.in?(current_user.edited_lectures_with_inheritance.map(&:id)) }
      @errors = { additional_lectures: ['Du hast nicht die nötigen Rechte dafür.'] }
      return
    end
    added_additional_lectures = (tag_params[:additional_lecture_ids].map(&:to_i) - [0]) - @tag.additional_lecture_ids
    unless current_user.admin? || added_additional_lectures.all? { |c| c.in?(current_user.edited_lectures_with_inheritance.map(&:id)) }
      @errors = { additional_lectures: ['Du hast nicht die nötigen Rechte dafür.'] }
      return
    end
    removed_disabled_lectures = @tag.disabled_lecture_ids - tag_params[:disabled_lecture_ids].map(&:to_i)
    unless current_user.admin? || removed_disabled_lectures.all? { |c| c.in?(current_user.edited_lectures_with_inheritance.map(&:id)) }
      @errors = { disabled_lectures: ['Du hast nicht die nötigen Rechte dafür.'] }
      return
    end
    added_disabled_lectures = (tag_params[:disabled_lecture_ids].map(&:to_i) - [0]) - @tag.disabled_lecture_ids
    unless current_user.admin? || added_disabled_lectures.all? { |c| c.in?(current_user.edited_lectures_with_inheritance.map(&:id)) }
      @errors = { disabled_lectures: ['Du hast nicht die nötigen Rechte dafür.'] }
      return
    end
    @tag.update(tag_params)
    @errors = @tag.errors unless @tag.valid?
  end

  def destroy
    @tag.destroy
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

end
