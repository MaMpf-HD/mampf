class VouchersController < ApplicationController
  load_and_authorize_resource
  before_action :find_voucher, only: :invalidate

  def current_ability
    @current_ability ||= VoucherAbility.new(current_user)
  end

  def create
    set_related_data
    respond_to do |format|
      if @voucher.save
        handle_successful_save(format)
      else
        handle_failed_save(format)
      end
    end
  end

  def invalidate
    set_related_data
    @voucher.update(invalidated_at: Time.zone.now)
    respond_to do |format|
      format.html { redirect_to edit_lecture_path(@lecture, anchor: "people") }
      format.js
    end
  end

  def verify
    @voucher = Voucher.find_voucher_by_hash(params[:secure_hash])
    respond_to do |format|
      if @voucher
        format.js
        format.html { head :no_content }
      else
        error_message = I18n.t("controllers.voucher_invalid")
        format.js { render "error", locals: { error_message: error_message } }
        format.html { redirect_to edit_profile_path, alert: error_message }
      end
    end
  end

  def redeem
    voucher = Voucher.find_voucher_by_hash(params[:secure_hash])
    if voucher
      voucher.redeem(params.permit(tutorial_ids: [], talk_ids: []))
      redirect_to edit_profile_path, notice: success_message(voucher)
    else
      handle_invalid_voucher
    end
  end

  def cancel
    respond_to do |format|
      format.html { redirect_to edit_profile_path }
      format.js
    end
  end

  private

    def voucher_params
      params.permit(:lecture_id, :role)
    end

    def find_voucher
      @voucher = Voucher.find_by(id: params[:id])
      return if @voucher

      handle_voucher_not_found
    end

    def set_related_data
      @lecture = @voucher.lecture
      @role = @voucher.role
      I18n.locale = @lecture.locale
    end

    def success_message(voucher)
      if voucher.tutor?
        I18n.t("controllers.become_tutor_success")
      elsif voucher.editor?
        I18n.t("controllers.become_editor_success")
      elsif voucher.teacher?
        I18n.t("controllers.become_teacher_success")
      elsif voucher.speaker?
        I18n.t("controllers.become_speaker_success")
      end
    end

    def handle_successful_save(format)
      format.html { redirect_to edit_lecture_path(@lecture, anchor: "people") }
      format.js
    end

    def handle_failed_save(format)
      error_message = @voucher.errors.full_messages.join(", ")
      format.html do
        redirect_to edit_lecture_path(@lecture, anchor: "people"),
                    alert: error_message
      end
      format.js do
        render "error", locals: { error_message: error_message }
      end
    end

    def handle_voucher_not_found
      I18n.locale = current_user.locale
      error_message = I18n.t("controllers.no_voucher")
      respond_to do |format|
        format.html do
          redirect_back(alert: error_message,
                        fallback_location: root_path)
        end
        format.js do
          render "error",
                 locals: { error_message: error_message }
        end
      end
    end

    def handle_invalid_voucher
      error_message = I18n.t("controllers.voucher_invalid")
      respond_to do |format|
        format.js { render "error", locals: { error_message: error_message } }
        format.html { redirect_to edit_profile_path, alert: error_message }
      end
    end
end
