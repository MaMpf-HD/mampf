# TagsController
class TagsController < ApplicationController
  before_action :set_tag, only: [:show]
  before_action :check_for_consent
  authorize_resource

  def index
    @tags = Tag.order(:title)
    @tags_with_id = @tags.map { |t| { id: t.id, title: t.title } }.to_json
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
end
