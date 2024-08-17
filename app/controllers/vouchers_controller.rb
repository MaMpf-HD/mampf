# app/controllers/vouchers_controller.rb
class VouchersController < ApplicationController
  include Notifier
  before_action :set_voucher, only: [:invalidate]
  authorize_resource except: :create

  def current_ability
    @current_ability ||= VoucherAbility.new(current_user)
  end

  def create
    @voucher = Voucher.new(voucher_params)
    set_related_data
    authorize! :create, @voucher
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
    @voucher = Voucher.check_voucher(check_voucher_params[:secure_hash])
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
    voucher = Voucher.check_voucher(check_voucher_params[:secure_hash])
    if voucher
      lecture = voucher.lecture
      redemption = process_voucher(voucher, lecture)
      redemption.create_notifications!
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
      params.permit(:lecture_id, :sort)
    end

    def check_voucher_params
      params.permit(:secure_hash, tutorial_ids: [])
    end

    def set_voucher
      @voucher = Voucher.find_by(id: params[:id])
      return if @voucher

      handle_voucher_not_found
    end

    def set_related_data
      @lecture = @voucher.lecture
      @sort = @voucher.sort
      I18n.locale = @lecture.locale
    end

    def process_voucher(voucher, lecture)
      if voucher.tutor?
        process_tutor_voucher(voucher, lecture)
      elsif voucher.editor?
        process_editor_voucher(voucher, lecture)
      elsif voucher.teacher?
        process_teacher_voucher(voucher, lecture)
      end
    end

    def process_tutor_voucher(voucher, lecture)
      selected_tutorials = lecture.tutorials
                                  .where(id: check_voucher_params[:tutorial_ids])
      lecture.update_tutor_status!(current_user, selected_tutorials)
      Redemption.create(user: current_user, voucher: voucher,
                        claimed_tutorials: selected_tutorials)
    end

    def process_editor_voucher(voucher, lecture)
      lecture.update_editor_status!(current_user)
      notify_new_editor_by_mail(current_user, lecture)
      Redemption.create(user: current_user, voucher: voucher)
    end

    def process_teacher_voucher(voucher, lecture)
      lecture.update_teacher_status!(current_user)
      # notify_new_teacher_by_mail(current_user, lecture)
      # notify_previous_teacher_by_mail(lecture)
      Redemption.create(user: current_user, voucher: voucher)
    end

    def success_message(voucher)
      if voucher.tutor?
        I18n.t("controllers.become_tutor_success")
      elsif voucher.editor?
        I18n.t("controllers.become_editor_success")
      elsif voucher.teacher?
        I18n.t("controllers.become_teacher_success")
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
