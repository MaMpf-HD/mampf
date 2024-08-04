# app/controllers/vouchers_controller.rb
class VouchersController < ApplicationController
  before_action :set_voucher, only: [:destroy]
  authorize_resource

  def current_ability
    @current_ability ||= VoucherAbility.new(current_user)
  end

  def destroy
    @lecture = @voucher.lecture
    @voucher.destroy
    respond_to do |format|
      format.html { head :no_content }
      format.js
    end
  end

  private

    def set_voucher
      @voucher = Voucher.find_by(id: params[:id])
      head :not_found unless @voucher
    end
end
