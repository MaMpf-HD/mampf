class ItemsController < ApplicationController
  before_action :set_item, except: [:create]
  authorize_resource except: [:create]

  def current_ability
    @current_ability ||= ItemAbility.new(current_user)
  end

  def edit
    I18n.locale = @item.medium.locale_with_inheritance if @item.medium
  end

  def create
    if params[:item][:locale].in?(I18n.available_locales.map(&:to_s))
      I18n.locale = params[:item][:locale]
    end
    @item = Item.new(item_params)
    I18n.locale = @item.medium.locale_with_inheritance if @item.medium
    authorize! :create, @item
    @item.save
    @errors = @item.errors unless @item.valid?
    # @from stores information about where the creation was triggered
    # @from is nil if the item was created as a toc item in thyme editor,
    # and 'referral' if it was triggered when creating an external item
    # for a reference
    @from = params[:item][:from]
    render :update
  end

  def update
    I18n.locale = @item.medium.locale_with_inheritance if @item.medium
    @item.update(item_params)
    @errors = @item.errors unless @item.valid?
  end

  def destroy
    @medium = @item.medium
    @item.destroy
    redirect_to edit_medium_path(@medium) if params[:from] == "quarantine"
  end

  # if an item is selected from within the reference editor in thyme,
  # the display action provides informations abut the selected item
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
      return @item.explanation if @referral_id.zero? || @item != Referral.find(@referral_id).item

      Referral.find(@referral_id).explanation
    end

    def item_params
      # params are cloned and then start time is converted to a TimeStamp object
      filter = params.expect(item: [:sort, :start_time, :section_id,
                                    :medium_id, :ref_number, :description,
                                    :link, :page, :pdf_destination,
                                    :explanation, :hidden]).clone
      if filter[:medium_id].present?
        filter[:start_time] = TimeStamp.new(time_string: filter[:start_time])
      end
      filter[:section_id] = nil if filter[:section_id] == ""
      filter
    end
end
