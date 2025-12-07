module Registration
  class ItemsController < ApplicationController
    before_action :set_campaign
    before_action :set_item, only: [:destroy, :update]

    def create
      @item = @campaign.registration_items.build(item_params)

      if @item.save
        redirect_to registration_campaign_path(@campaign, tab: "items"),
                    notice: t("registration.item.created")
      else
        redirect_to registration_campaign_path(@campaign, tab: "items"),
                    alert: @item.errors.full_messages.to_sentence
      end
    end

    def update
      registerable = @item.registerable

      if registerable.update(capacity_params)
        respond_to do |format|
          format.turbo_stream
          format.html do
            redirect_to registration_campaign_path(@campaign, tab: "items"),
                        notice: t("registration.item.updated")
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(@item, partial: "registration/items/item",
                                                             locals: { item: @item })
          end
          format.html do
            redirect_to registration_campaign_path(@campaign, tab: "items"),
                        alert: registerable.errors.full_messages.to_sentence
          end
        end
      end
    end

    def destroy
      unless @campaign.draft?
        redirect_to registration_campaign_path(@campaign, tab: "items"),
                    alert: t("registration.item.cannot_destroy")
        return
      end

      @item.destroy
      redirect_to registration_campaign_path(@campaign, tab: "items"),
                  notice: t("registration.item.destroyed")
    end

    private

      def set_campaign
        @campaign = Registration::Campaign.find(params[:campaign_id])
        authorize! :update, @campaign
      end

      def set_item
        @item = @campaign.registration_items.find(params[:id])
      end

      def item_params
        params.expect(registration_item: [:registerable_id, :registerable_type])
      end

      def capacity_params
        params.expect(registration_item: [:capacity])
      end
  end
end
