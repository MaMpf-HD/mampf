# Referrals controller
class ReferralsController < ApplicationController
  before_action :set_referral, only: [:update, :edit, :destroy]
  before_action :set_basics, only: [:update, :create]

  def update
    update_or_create_item
    return if @errors.present?
    @referral.update(updated_params)
    @errors = @referral.errors unless @referral.valid?
  end

  def edit
    @item_selection = @referral.medium.items_for_thyme
    @item = Item.new(sort: 'link')
  end

  def create
    update_or_create_item
    if @errors.present?
      render :update
      return
    end
    @referral = Referral.create(updated_params)
    @errors = @referral.errors unless @referral.valid?
    render :update
  end

  def destroy
    @medium = @referral.medium
    @referral.destroy
  end

  private

  def set_referral
    @referral = Referral.find(params[:id])
  end

  def set_basics
    @video = params[:referral][:video]
    @manuscript = params[:referral][:manuscript]
    @medium_link = params[:referral][:medium_link]
    @item_id = params[:referral][:item_id].to_i
  end

  def referral_params
    filter = params.require(:referral).permit(:medium_id, :item_id, :start_time,
                                              :end_time, :description, :link,
                                              :video, :manuscript, :medium_link,
                                              :explanation, :ref_id).clone
    filter[:start_time] = TimeStamp.new(time_string: filter[:start_time])
    filter[:end_time] = TimeStamp.new(time_string: filter[:end_time])
    filter
  end

  def create_item
    item = Item.create(sort: 'link', link: referral_params[:link],
                       description: referral_params[:description],
                       explanation: referral_params[:explanation])
    @errors = item.errors unless item.valid?
    @item_id = item.id
    @video = nil
    @manuscript = nil
  end

  def update_item
    item = Item.find(@item_id)
    item.update(link: referral_params[:link],
                description: referral_params[:description],
                explanation: referral_params[:explanation])
    @errors = item.errors unless item.valid?
    @video = nil
    @manuscript = nil
  end

  def update_or_create_item
    if @item_id.zero?
      create_item
    elsif @item_id != 0 && Item.find(@item_id).sort == 'link'
      update_item
    end
  end

  def updated_params
    { medium_id: referral_params[:medium_id], item_id: @item_id,
      explanation: referral_params[:explanation],
      start_time: referral_params[:start_time],
      end_time: referral_params[:end_time],
      video: @video, manuscript: @manuscript, medium_link: @medium_link }
  end
end
