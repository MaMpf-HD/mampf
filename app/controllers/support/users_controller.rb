module Support
  # Lets the support find a person and correct what they cannot change
  # themselves once saved: their name and matriculation number.
  class UsersController < ApplicationController
    before_action :authorize_support
    before_action :set_user, only: [:edit, :update]

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
      set_changes
    end

    def update
      fields = PersonalDataChange.correct(@user, personal_data_params, editor: current_user)
      if fields
        notice = t(fields.any? ? "support.users.saved" : "support.users.unchanged")
        redirect_to edit_support_user_path(@user), notice: notice, status: :see_other
      else
        set_changes
        render :edit, status: :unprocessable_content
      end
    end

    private

      def authorize_support
        authorize! action_name.to_sym, :support
      end

      def set_user
        @user = User.find(params[:id])
      end

      def set_changes
        @changes = @user.personal_data_changes.includes(:editor).order(created_at: :desc)
      end

      def personal_data_params
        params.expect(user: User::LOCKED_PERSONAL_DATA_FIELDS)
      end

      def search_params
        params.fetch(:search, {}).permit(:fulltext, :all_programs, program_ids: [])
      end
  end
end
