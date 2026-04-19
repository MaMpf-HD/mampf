module Registration
  class PoliciesController < ApplicationController
    before_action :set_campaign
    before_action :set_locale
    before_action :set_policy, only: [:edit, :update, :destroy, :move_up, :move_down]
    authorize_resource class: "Registration::Policy",
                       except: [:new, :create, :reorder]

    def current_ability
      @current_ability ||= RegistrationPolicyAbility.new(current_user)
    end

    def new
      @policy = @campaign.registration_policies.build
      authorize! :new, @policy
    end

    def edit
    end

    def create
      @policy = @campaign.registration_policies.build(policy_params)
      authorize! :create, @policy

      if @policy.save
        flash_and_update(:notice, t("registration.policy.created"))
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @policy.update(policy_params)
        flash_and_update(:notice, t("registration.policy.updated"))
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @policy.destroy
        flash_and_update(:notice, t("registration.policy.destroyed"))
      else
        respond_with_flash(:alert, @policy.errors.full_messages.join(", "),
                           redirect_path: policy_redirect_path)
      end
    end

    def move_up
      move(:higher)
    end

    def move_down
      move(:lower)
    end

    def reorder
      authorize! :update, @campaign.registration_policies.build
      policy_ids = params[:policy_ids]
      return head(:bad_request) unless policy_ids.is_a?(Array)

      Registration::Policy.transaction do
        policy_ids.each_with_index do |id, index|
          @campaign.registration_policies.find(id).set_list_position(index + 1)
        end
      end
      flash_and_update(:notice, nil)
    end

    private

      def set_campaign
        @campaign = Registration::Campaign.find_by(id: params[:registration_campaign_id])
        return if @campaign

        respond_with_flash(:alert, t("registration.campaign.not_found"),
                           redirect_path: root_path)
      end

      def set_policy
        @policy = @campaign.registration_policies.find_by(id: params[:id])
        return if @policy

        respond_with_flash(:alert,
                           t("registration.policy.not_found"),
                           redirect_path: registration_campaign_path(
                             @campaign, anchor: "policies-tab"
                           ))
      end

      def set_locale
        I18n.locale = @campaign&.locale_with_inheritance || I18n.locale
      end

      def policy_params
        params.expect(registration_policy: [:kind, :phase, :allowed_domains,
                                            :prerequisite_campaign_id,
                                            :lecture_id])
      end

      def move(direction)
        @policy.public_send("move_#{direction}")
        flash_and_update(:notice, nil)
      end

      def render_campaigns_container
        @campaign.reload
        turbo_stream.update("campaigns_container",
                            partial: "registration/campaigns/card_body_index",
                            locals: {
                              lecture: @campaign.campaignable,
                              expanded_campaign_id: @campaign.id
                            })
      end

      def flash_and_update(flash_type, message)
        @campaign.reload
        if exam_campaign_context?
          flash.now[flash_type] = message if message
          return render_exam_update("exams/settings")
        end

        respond_with_flash(flash_type, message,
                           redirect_path: policy_redirect_path) do
          render_campaigns_container
        end
      end

      def policy_redirect_path
        if exam_campaign_context?
          exam = @campaign.registration_items
                          .find_by(registerable_type: "Exam")
                          &.registerable
          return exam_path(exam, tab: "settings") if exam
        end

        registration_campaign_path(@campaign, anchor: "policies-tab")
      end

      def target_frame_id
        params[:frame_id].presence || "campaigns_container"
      end

      def exam_campaign_context?
        target_frame_id != "campaigns_container" &&
          @campaign.exam_campaign?
      end

      def render_exam_update(partial)
        exam = @campaign.registration_items
                        .find_by(registerable_type: "Exam")
                        .registerable
        render turbo_stream: [
          turbo_stream.replace(
            target_frame_id,
            partial: partial,
            locals: { exam: exam, lecture: exam.lecture }
          ),
          stream_flash
        ].compact
      end
  end
end
