# TagsController
class TagsController < ApplicationController
  before_action :set_tag, only: [:show]
  before_action :check_for_consent
  authorize_resource

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
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
