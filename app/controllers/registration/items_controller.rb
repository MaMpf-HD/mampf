module Registration
  class ItemsController < ApplicationController
    before_action :set_campaign
    before_action :set_locale
    before_action :set_item, only: [:destroy, :update]
    authorize_resource class: "Registration::Item", except: [:create]

    def current_ability
      @current_ability ||= RegistrationItemAbility.new(current_user)
    end

    def create
      if params[:registration_item][:new_registerable].present?
        create_new_registerable
      else
        create_existing_item
      end
    end

    def update
      if @item.update(capacity_params)
        respond_to do |format|
          format.html do
            redirect_to registration_campaign_path(@campaign, tab: "items"),
                        notice: t("registration.item.updated")
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.item.updated")
            render turbo_stream: [
              turbo_stream.replace(@item, partial: "registration/items/item", locals: { item: @item }),
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

    private

      def create_existing_item
        @item = @campaign.registration_items.build(item_params)
        authorize! :create, @item

        if @item.save
          respond_to_success
        else
          respond_to_failure
        end
      end

      def create_new_registerable
        authorize! :update, @campaign.campaignable # Ensure user can edit the lecture

        type = params[:registration_item][:registerable_type]
        title = params[:registration_item][:title]
        capacity = params[:registration_item][:capacity]

        unless ["Tutorial", "Talk"].include?(type)
          @item = @campaign.registration_items.build
          @item.errors.add(:base, "Invalid type")
          return respond_to_failure
        end

        ActiveRecord::Base.transaction do
          registerable = type.constantize.new(
            lecture: @campaign.campaignable,
            title: title,
            capacity: capacity
          )

          unless registerable.save
            @item = @campaign.registration_items.build
            registerable.errors.full_messages.each { |m| @item.errors.add(:base, m) }
            raise ActiveRecord::Rollback
          end

          @item = @campaign.registration_items.build(
            registerable: registerable,
            registerable_type: type
          )

          unless @item.save
            raise ActiveRecord::Rollback
          end
        end

        if @item.persisted?
          respond_to_success
        else
          respond_to_failure
        end
      end

      def respond_to_success
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
              turbo_stream.update("items-tab-count", @campaign.registration_items.count),
              stream_flash
            ]
          end
        end
      end

      def respond_to_failure
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

      def set_campaign
            redirect_to registration_campaign_path(@campaign, tab: "items"),
                        notice: t("registration.item.updated")
          end
          format.turbo_stream do
            flash.now[:notice] = t("registration.item.updated")
            render turbo_stream: [
              turbo_stream.replace(@item, partial: "registration/items/item",
                                          locals: { item: @item }),
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
            render turbo_stream: turbo_stream.replace(@item, partial: "registration/items/item",
                                                             locals: { item: @item })
          end
        end
      end
    end

    def destroy
      unless @campaign.draft?
        redirect_to registration_campaign_path(@campaign, tab: "items"),
                    alert: t("activerecord.errors.models.registration/item.attributes.base.frozen")
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
            turbo_stream.update("items-tab-count", @campaign.registration_items.count),
            stream_flash
          ]
        end
      end
    end

    private

      def set_campaign
        @campaign = Registration::Campaign.find(params[:registration_campaign_id])
      end

      def set_locale
        I18n.locale = @campaign&.locale_with_inheritance || I18n.locale
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
