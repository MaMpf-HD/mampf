# Referrals controller
class ReferralsController < ApplicationController
  before_action :set_referral, only: [:update, :edit, :destroy]
  before_action :set_basics, only: [:update, :create]

  def update
    # if referral's item is a link, it is updated
    # this means in particular that *all referrals* that refer to it will
    # be affected; links are changed *globally*
    update_item if Item.find_by_id(@item_id)&.sort == 'link'
    return if @errors.present?
    @referral.update(updated_params)
    @errors = @referral.errors unless @referral.valid?
  end

  def edit
    # if referral's item is a link, load all other links,
    # otherwise load all items in the referral's item's medium scope
    # that the user can choose from in the item dropdown menu
    @item_selection = if @referral.item.sort == 'link'
                        Item.where(medium: nil)
                            .map { |i| [i.description, i.id] }
                      else
                        @referral.item.medium.teachable.media_scope
                                 .media_items_with_inheritance
                      end
    @item = Item.new(sort: 'link')
  end

  def create
    update_item if Item.find_by_id(@item_id)&.sort == 'link'
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

  # load all relevant items after user's choice of a teachable
  # in the preselection dropdown, they are to populate the item dropdown
  # renders it in json as it will be called by ajax
  def list_items
    teachable_id = params[:teachable_id].to_s.split('-')
    if teachable_id[0] == 'external'
      result = Item.where(medium: nil).map { |i| [i.description, i.id] }
    else
      @teachable = teachable_id[0].constantize.find_by_id(teachable_id[1])
      result = @teachable.media_items_with_inheritance
    end
    render json: result
  end

  private

  def set_referral
    @referral = Referral.find(params[:id])
  end

  def set_basics
    @item_id = params[:referral][:item_id].to_i
  end

  def referral_params
    # clone referral params in order to convert start and end time to proper
    # TimeStamp instances
    filter = params.require(:referral).permit(:medium_id, :item_id, :start_time,
                                              :end_time, :description, :link,
                                              :explanation, :ref_id).clone
    filter[:start_time] = TimeStamp.new(time_string: filter[:start_time])
    filter[:end_time] = TimeStamp.new(time_string: filter[:end_time])
    filter
  end

  def update_item
    item = Item.find(@item_id)
    item.update(link: referral_params[:link],
                description: referral_params[:description])
    @errors = item.errors unless item.valid?
  end

  def updated_params
    { medium_id: referral_params[:medium_id], item_id: @item_id,
      explanation: referral_params[:explanation],
      start_time: referral_params[:start_time],
      end_time: referral_params[:end_time] }
  end
end
