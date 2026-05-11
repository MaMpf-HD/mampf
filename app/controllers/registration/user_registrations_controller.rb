module Registration
  class UserRegistrationsController < ApplicationController
    before_action :set_campaign
    before_action :set_locale

    def current_ability
      @current_ability ||= RegistrationUserRegistrationAbility.new(current_user)
    end

    def reject_for_user
      return if campaign_completed?

      @user = User.find(params[:user_id])
      registrations = @campaign.user_registrations.where(user: @user)

      return if no_registrations_found?(registrations)

      # Authorize based on the first registration (all belong to same campaign)
      authorize! :destroy, registrations.first

      reject_registrations(registrations)
    end

    private

      def evaluate_turbo_stream_response
        streams = [turbo_stream.replace("flash-messages", partial: "flash/messages")]

        if ["allocation", "allocation_embedded"].include?(params[:source])
          load_allocation_data
          if params[:source] == "allocation_embedded"
            exam = @campaign.exam
            if exam
              streams << turbo_stream.replace(
                Registration::Campaign.exam_workspace_frame_id(exam),
                partial: "registration/allocations/exam_workspace",
                locals: {
                  campaign: @campaign,
                  dashboard: @dashboard,
                  exam: exam,
                  container_id: Registration::Campaign.exam_workspace_frame_id(exam)
                }
              )
            else
              streams << turbo_stream.replace("allocation-dashboard",
                                              partial: "registration/allocations/dashboard",
                                              locals: {
                                                campaign: @campaign,
                                                dashboard: @dashboard,
                                                embedded: true
                                              })
            end
            streams << turbo_stream.replace(
              helpers.campaign_actions_id(@campaign),
              partial: "registration/campaigns/card_body_actions",
              locals: {
                campaign: @campaign,
                has_violators: @dashboard.blockers?
              }
            )
          else
            streams << turbo_stream.replace("allocation-dashboard",
                                            partial: "registration/allocations/dashboard",
                                            locals: {
                                              campaign: @campaign,
                                              dashboard: @dashboard
                                            })
          end
        end

        streams
      end

      def load_allocation_data
        @dashboard = Registration::AllocationDashboard.new(@campaign)
      end

      def set_campaign
        @campaign = Registration::Campaign.find_by(id: params[:registration_campaign_id])
        return if @campaign

        respond_with_flash(:alert, t("registration.campaign.not_found"),
                           fallback_location: root_path)
      end

      def set_locale
        I18n.locale = @campaign&.campaignable&.locale_with_inheritance || I18n.locale
      end

      def campaign_completed?
        return false unless @campaign.completed?

        respond_with_flash(:alert, t("registration.campaign.errors.already_finalized"),
                           fallback_location: registration_campaign_path(@campaign))
        true
      end

      def no_registrations_found?(registrations)
        return false if registrations.any?

        redirect_back_or_to(registration_campaign_path(@campaign),
                            alert: t("registration.user_registration.none"))
        true
      end

      def reject_registrations(registrations)
        registrations = registrations.where.not(status: :rejected).to_a
        count = registrations.size
        reason_code, reason_label = rejection_reason

        Registration::UserRegistration.transaction do
          registrations.each do |registration|
            registration.reject!(
              reason_type: Registration::UserRegistration::REJECTION_REASON_TYPE_MANUAL,
              reason_code: reason_code,
              reason_label: reason_label
            )
          end
        end

        respond_with_flash(:notice,
                           t("registration.user_registration.rejected_all_for_user",
                             count: count),
                           fallback_location: registration_campaign_path(@campaign)) do
          evaluate_turbo_stream_response
        end
      rescue ActiveRecord::RecordInvalid
        respond_with_flash(:alert, t("registration.user_registration.reject_failed"),
                           fallback_location: registration_campaign_path(@campaign))
      end

      def rejection_reason
        if params[:reason] == Registration::UserRegistration::REJECTION_REASON_CODE_DEFERRED_DUE_TO_BLOCKER
          [
            Registration::UserRegistration::REJECTION_REASON_CODE_DEFERRED_DUE_TO_BLOCKER,
            t("registration.user_registration.reason_labels.deferred_due_to_blocker")
          ]
        else
          [
            Registration::UserRegistration::REJECTION_REASON_CODE_WITHDRAWN_BY_TEACHER,
            t("registration.user_registration.reason_labels.withdrawn_by_teacher")
          ]
        end
      end
  end
end
