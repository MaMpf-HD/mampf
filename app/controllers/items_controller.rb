# ItemsController
class ItemsController < ApplicationController
  before_action :set_item, except: [:create]

  def update
    @item.update(item_params)
    @errors = @item.errors unless @item.valid?
  end

  def edit
  end

  def create
    @item = Item.create(item_params)
    @errors = @item.errors unless @item.valid?
    render :update
  end

  def destroy
    @medium = @item.medium
    @item.destroy
  end

  def display
    @referral_id = params[:referral_id].to_i
    @reappears = true if (@item.referrals.map(&:id) - [@referral_id]).present?
    @explanation = set_explanation
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def set_explanation
    return if @referral_id.zero? || @item != Referral.find(@referral_id).item
    return @item.explanation if @item.sort == 'link'
    Referral.find(@referral_id).explanation
  end

  def item_params
    filter = params.require(:item).permit(:sort, :start_time, :section_id,
                                          :medium_id, :ref_number, :description,
                                          :link, :page, :pdf_destination).clone
    if filter[:medium_id].present?
      filter[:start_time] = TimeStamp.new(time_string: filter[:start_time])
    end
    filter[:section_id] = nil if filter[:section_id] == ''
    filter
  end
end
