# app/controllers/vouchers_controller.rb
class VouchersController < ApplicationController
  before_action :set_voucher, only: [:destroy]
  authorize_resource

  def current_ability
    @current_ability ||= VoucherAbility.new(current_user)
  end

  def create
    @lecture = Lecture.find_by(id: voucher_params[:lecture_id])
    I18n.locale = @lecture.locale
    @voucher = Voucher.new(lecture: @lecture, sort: voucher_params[:sort])
    respond_to do |format|
      if @voucher.save
        handle_successful_save(format)
      else
        handle_failed_save(format)
      end
    end
  end

  def destroy
    @lecture = @voucher.lecture
    I18n.locale = @lecture.locale
    @voucher.destroy
    respond_to do |format|
      format.html { redirect_to edit_lecture_path(@lecture, anchor: "people") }
      format.js
    end
  end

  private

    def voucher_params
      params.permit(:lecture_id, :sort)
    end

    def set_voucher
      @voucher = Voucher.find_by(id: params[:id])
      return if @voucher

      handle_voucher_not_found
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
        render "create_error", locals: { error_message: error_message }
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
          render "no_voucher_error",
                 locals: { error_message: error_message }
        end
      end
    end
end
