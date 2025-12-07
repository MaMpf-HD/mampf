module Registration
  class ItemsController < ApplicationController
    before_action :set_campaign
    before_action :set_item, only: [:destroy, :update]
    authorize_resource class: "Registration::Item", except: [:create]

    def current_ability
      @current_ability ||= RegistrationItemAbility.new(current_user)
    end

    def create
      @item = @campaign.registration_items.build(item_params)
      authorize! :create, @item

      if @item.save
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign, tab: "items"),
                        notice: t("registration.item.created")
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.item.created")
            render turbo_stream: [
              turbo_stream.replace("registration_items_container",
                                   partial: "registration/campaigns/card_body_items",
                                   locals: { campaign: @campaign }),
              stream_flash
            ]
          end
        end
      else
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign, tab: "items"),
                        alert: @item.errors.full_messages.to_sentence
          end
          format.turbo_stream do
            flash.now[:alert] = @item.errors.full_messages.to_sentence
            render turbo_stream: stream_flash
          end
        end
      end
    end

    def update
      registerable = @item.registerable

      if registerable.update(capacity_params)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign, tab: "items"),
                        notice: t("registration.item.updated")
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.item.updated")
            render turbo_stream: [
              turbo_stream.replace(dom_id(@item), partial: "registration/items/item",
                                                  locals: { item: @item }),
              stream_flash
            ]
          end
        end
      else
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign, tab: "items"),
                        alert: registerable.errors.full_messages.to_sentence
          end
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(dom_id(@item), partial: "registration/items/item",
                                                                     locals: { item: @item })
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
      respond_to do |format|
        format.html do
          redirect_to registration_campaign_path(@campaign, tab: "items"),
                      notice: t("registration.item.destroyed")
        end
        format.turbo_stream do
          flash.now[:notice] = t("registration.item.destroyed")
          render turbo_stream: [
            turbo_stream.replace("registration_items_container",
                                 partial: "registration/campaigns/card_body_items",
                                 locals: { campaign: @campaign }),
            stream_flash
          ]
        end
      end
    end

    private

      def set_campaign
        @campaign = Registration::Campaign.find(params[:registration_campaign_id])
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
