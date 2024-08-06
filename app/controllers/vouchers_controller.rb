# app/controllers/vouchers_controller.rb
class VouchersController < ApplicationController
  before_action :set_voucher, only: [:destroy]
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

  def destroy
    set_related_data
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

    def set_related_data
      @lecture = @voucher.lecture
      @sort = @voucher.sort
      I18n.locale = @lecture.locale
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
