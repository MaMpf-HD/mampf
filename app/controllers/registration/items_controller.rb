module Registration
  class ItemsController < ApplicationController
    before_action :set_campaign
    before_action :set_locale
    before_action :set_item, only: [:destroy, :update]
    authorize_resource class: "Registration::Item", except: [:create]

    REGISTERABLE_CLASSES = {
      "Tutorial" => Tutorial,
      "Talk" => Talk
    }.freeze

    def current_ability
      @current_ability ||= begin
        ability = RegistrationItemAbility.new(current_user)
        # We need to merge TutorialAbility and TalkAbility because the view renders
        # registration items which delegate permission checks to their registerables
        # (Tutorials/Talks). Without this, can?(:destroy, item.registerable) fails.
        ability.merge(TutorialAbility.new(current_user))
        ability.merge(TalkAbility.new(current_user))
        ability
      end
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
            redirect_to after_action_path,
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
        messages = @item.errors.full_messages
        messages += @item.registerable.errors.full_messages if @item.registerable&.errors&.any?
        respond_with_error(messages.uniq.to_sentence)
      end
    end

    def destroy
      unless @campaign.draft?
        respond_with_error(t("activerecord.errors.models.registration/item.attributes.base.frozen"))
        return
      end

      if params[:cascade] == "true"
        destroy_cascading
      else
        destroy_item_only
      end
    end

    private

      def destroy_item_only
        @item.destroy
        respond_with_success(t("registration.item.destroyed"))
      end

      def destroy_cascading
        registerable = @item.registerable
        authorize! :destroy, registerable

        if perform_cascading_destroy(registerable)
          message = t("registration.item.registerable_destroyed",
                      type: t("registration.item.types.#{registerable.class.name.underscore}"))
          respond_with_success(message)
        else
          respond_with_error(registerable.errors.full_messages.to_sentence)
        end
      end

      def perform_cascading_destroy(registerable)
        success = false
        ActiveRecord::Base.transaction do
          @item.destroy
          raise(ActiveRecord::Rollback) unless registerable.destroy

          success = true
        end
        success
      end

      def create_existing_item
        @item = @campaign.registration_items.build(item_params)
        authorize! :create, @item

        if @item.save
          respond_with_success(t("registration.item.created"))
        else
          respond_with_error(@item.errors.full_messages.to_sentence)
        end
      end

      def create_new_registerable
        type = params[:registration_item][:registerable_type]
        unless REGISTERABLE_CLASSES.key?(type)
          return respond_with_error(t("registration.item.invalid_type"))
        end

        if save_new_registerable_item(type)
          respond_with_success(t("registration.item.created"))
        else
          respond_with_error(@item.errors.full_messages.to_sentence)
        end
      end

      def save_new_registerable_item(type)
        registerable = build_registerable(type)
        authorize! :create, registerable

        persist_registerable_and_item(registerable, type)
      end

      def build_registerable(type)
        REGISTERABLE_CLASSES[type].new(
          lecture: @campaign.campaignable,
          title: params[:registration_item][:title],
          capacity: params[:registration_item][:capacity]
        )
      end

      def persist_registerable_and_item(registerable, type)
        ActiveRecord::Base.transaction do
          unless registerable.save
            build_item_with_errors(registerable)
            raise(ActiveRecord::Rollback)
          end

          build_and_authorize_item(registerable, type)
          raise(ActiveRecord::Rollback) unless @item.save
        end
        @item&.persisted?
      end

      def build_item_with_errors(registerable)
        @item = @campaign.registration_items.build
        registerable.errors.full_messages.each { |m| @item.errors.add(:base, m) }
      end

      def build_and_authorize_item(registerable, type)
        @item = @campaign.registration_items.build(
          registerable: registerable,
          registerable_type: type
        )
        authorize! :create, @item
      end

      def respond_with_success(message)
        @campaign.reload
        respond_to do |format|
          format.html do
            redirect_to after_action_path, notice: message
          end
          format.turbo_stream do
            flash.now[:notice] = message
            render turbo_stream: [
              turbo_stream.replace("registration_items_container",
                                   partial: "registration/campaigns/card_body_items",
                                   locals: { campaign: @campaign }),
              turbo_stream.update("items-tab-count", @campaign.registration_items.count),
              turbo_stream.update("settings",
                                  partial: "registration/campaigns/form",
                                  locals: { campaign: @campaign, lecture: @campaign.campaignable }),
              stream_flash
            ]
          end
        end
      end

      def respond_with_error(message)
        respond_to do |format|
          format.html do
            redirect_to after_action_path, alert: message
          end
          format.turbo_stream do
            flash.now[:alert] = message
            render turbo_stream: stream_flash
          end
        end
      end

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

      def after_action_path
        if @campaign.campaignable.is_a?(Lecture)
          edit_lecture_path(@campaign.campaignable, tab: "campaigns")
        else
          registration_campaign_path(@campaign, tab: "items")
        end
      end
  end
end
