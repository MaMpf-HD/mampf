# UsersController
class UsersController < ApplicationController
  layout "administration"

  def current_ability
    @current_ability ||= UserAbility.new(current_user)
  end

  def teacher
    @teacher = User.find_by(id: params[:teacher_id])
    authorize! :teacher, @teacher
    if @teacher.present? && @teacher.teacher?
      render layout: "application"
      return
    end
    redirect_to :root,
                alert: I18n.t("controllers.no_teacher")
  end

  def image
    @user = User.find_by(id: params[:id])
    return head :not_found if @user.nil?

    authorize! :image, @user

    file = image_file_for(@user, image_variant_for(@user))
    return head :not_found if file.nil?

    send_stored_file(file, disposition: "inline", fallback: @user.image_filename || "user-image")
  end

  def fill_user_select
    authorize! :fill_user_select, User.new
    if params[:q]
      result = User.preferred_name_or_email_like(params[:q])
                   .values_for_select
      render json: result
      return
    end
    result = User.values_for_select
    render json: result
  end

  def delete_account
    authorize! :delete_account, User.new
  end

  private

    # Only the owner and admins may fetch the original upload (full resolution
    # and EXIF). Everyone else — e.g. a student viewing a teacher profile — is
    # served the resized, metadata-stripped derivative.
    def image_variant_for(user)
      return params[:variant] if current_user&.admin? || current_user == user

      "normalized"
    end

    def image_file_for(user, variant)
      case variant
      when "original"
        user.original_image_file
      when "normalized"
        user.normalized_image_file
      end
    end
end
