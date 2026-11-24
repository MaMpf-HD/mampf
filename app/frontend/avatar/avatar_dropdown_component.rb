class AvatarDropdownComponent < ViewComponent::Base
  Item = Struct.new(:path, :icon, :label, :active, keyword_init: true)

  def initialize(user:)
    super()
    @user = user
  end

  def item_groups
    [personal_items, role_items].reject(&:empty?)
  end

  def display_name
    @user.full_name || @user.name_or_email
  end

  def logout_path
    destroy_user_session_path(params: { locale: @user.locale })
  end

  private

    def personal_items
      [
        item(edit_profile_path, "bi-person-circle", t("navbar.profile")),
        item(annotations_path, "bi-stickies-fill", t("navbar.my_annotations")),
        item(watchlists_path, "bi-tv-fill", t("navbar.my_watchlists"),
             active: request.path.starts_with?(watchlists_path))
      ]
    end

    def role_items
      items = []
      if @user.support? || @user.admin?
        items << item(support_users_path, "bi-life-preserver", t("support.title"))
      end
      if @user.deans_office? || @user.admin?
        items << item(deans_office_path, "bi-building", t("deans_office.title"))
      end
      if @user.admin?
        items << item(administration_path, "bi-tools", t("navbar.administration"),
                      active: false)
      end
      items
    end

    def item(path, icon, label, active: request.path == path)
      Item.new(path: path, icon: icon, label: label, active: active)
    end
end
