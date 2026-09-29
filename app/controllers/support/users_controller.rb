module Support
  # Lets the support find a person, correct their personal data but the
  # address, see whether their account is locked or unconfirmed, and send the
  # mails that get them back in.
  class UsersController < ApplicationController
    helper SupportUsersHelper
    helper PersonalDataHelper

    # No email: whoever types a new address gets its confirmation link, so the
    # support could move any account to themselves. People change it in their
    # own account settings, behind their password.
    FIELDS = [:first_name, :last_name, :matriculation_number, :program_id, :uni_id,
              :name, :name_in_tutorials].freeze

    before_action :authorize_support_area
    before_action :set_user, except: :index
    helper_method :search_query, :search_values

    SearchValues = Struct.new(:fulltext, :all_programs, :program_ids, keyword_init: true)

    def current_ability
      @current_ability ||= SupportAbility.new(current_user)
    end

    def index
      @pagy, @users = Search::Searchers::ControllerSearcher.search(
        controller: self,
        model_class: User,
        configurator_class: Search::Configurators::UserSearchConfigurator,
        options: { default_per_page: 20 }
      )
      @users = @users.includes(User::PROGRAM_PRELOAD)
    end

    def edit
      authorize! :edit, @user
    end

    def update
      authorize! :update, @user
      @user.assign_attributes(user_params)
      return back_to_person(t("support.users.unchanged")) unless @user.changed?

      saved = @user.admin_changed? ? @user.save_admin_change(by: current_user) : @user.save
      if saved
        back_to_person(t("support.users.saved"))
      else
        render :edit, status: :unprocessable_content
      end
    end

    def unlock
      authorize! :unlock, @user
      @user.unlock_access!
      back_to_person(t("support.users.unlocked"))
    end

    def password_reset
      authorize! :password_reset, @user
      @user.send_reset_password_instructions
      back_to_person(t("support.users.password_reset_sent"))
    end

    def confirmation
      authorize! :confirmation, @user
      if @user.resend_confirmation_instructions
        back_to_person(t("support.users.confirmation_sent"))
      else
        back_to_person(t("support.users.nothing_to_confirm"), kind: :alert)
      end
    end

    def destroy
      authorize! :destroy, @user
      return back_to_person(t("support.users.not_deleted"), kind: :alert) unless destroy_person

      redirect_to support_users_path(search: search_query),
                  notice: t("support.users.deleted", user: @user.email), status: :see_other
    end

    private

      # Asked before any account is loaded, so that nobody outside the support
      # learns from the answer whether an id exists.
      def authorize_support_area
        authorize! :index, :support
      end

      # Exam registrations and other records the university keeps refer to
      # the account; such an account stays, and the page says so.
      def destroy_person
        @user.destroy
      rescue ActiveRecord::InvalidForeignKey, ActiveRecord::DeleteRestrictionError
        false
      end

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        fields = FIELDS
        fields += [:support, :deans_office] if can?(:assign_roles, @user)
        fields += [:admin] if can?(:assign_admin, @user)
        params.expect(user: fields)
      end

      def back_to_person(message, kind: :notice)
        redirect_to edit_support_user_path(@user, search: search_query), kind => message,
                                                                         status: :see_other
      end

      def search_params
        search = params[:search]
        return ActionController::Parameters.new.permit unless search.respond_to?(:permit)

        search.permit(:fulltext, :all_programs, program_ids: [])
      end

      # The search the page was opened from, so that going back finds it again.
      def search_query
        search_params.to_h.presence
      end

      def search_values
        SearchValues.new(**search_params.to_h.symbolize_keys) if search_query
      end
  end
end
