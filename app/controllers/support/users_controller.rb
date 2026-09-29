module Support
  # Lets the support find a person, correct all of their personal data, see
  # whether their account is locked or unconfirmed, and send the mails that
  # get them back in.
  class UsersController < ApplicationController
    helper SupportUsersHelper
    helper PersonalDataHelper

    FIELDS = [:first_name, :last_name, :matriculation_number, :program_id, :uni_id,
              :name, :name_in_tutorials, :email].freeze

    before_action :set_user, except: :index
    helper_method :search_query, :search_values

    # The query as the search form reads it back into its fields.
    SearchValues = Struct.new(:fulltext, :all_programs, :program_ids, keyword_init: true)

    def current_ability
      @current_ability ||= SupportAbility.new(current_user)
    end

    def index
      authorize! :index, :support
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

      if @user.save
        back_to_person(saved_notice)
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
      @user.resend_confirmation_instructions
      back_to_person(t("support.users.confirmation_sent"))
    end

    private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        fields = FIELDS
        fields += [:support] if can?(:assign_support, @user)
        params.expect(user: fields)
      end

      def back_to_person(notice)
        redirect_to edit_support_user_path(@user, search: search_query), notice: notice,
                                                                         status: :see_other
      end

      # A new address holds only once its owner confirms it.
      def saved_notice
        return t("support.users.saved") unless @user.saved_change_to_unconfirmed_email?

        t("support.users.saved_email_pending", email: @user.unconfirmed_email)
      end

      def search_params
        params.fetch(:search, {}).permit(:fulltext, :all_programs, program_ids: [])
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
