class MediumAbility
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    clear_aliased_actions

    can [:index, :new], Medium

    can [:show, :show_comments], Medium do |medium|
      medium.visible_for_user?(user)
    end

    can :inspect, Medium do |medium|
      !user.generic? && medium.visible_for_user?(user)
    end

    can [:edit, :update, :enrich, :publish, :destroy, :cancel_publication,
         :add_item, :add_reference, :add_screenshot, :remove_screenshot,
         :import_script_items, :export_toc, :export_references,
         :export_screenshot, :import_manuscript,
         :get_statistics], Medium do |medium|
      user.can_edit?(medium)
    end

    can :create, Medium do |medium|
      user.can_edit?(medium.teachable)
    end

    can [:search, :fill_teachable_select, :fill_media_select], Medium do
      !user.generic?
    end

    # guest users can play/display media when their release status 'all'
    can [:play, :display, :geogebra], Medium do |medium|
      (!user.new_record? && medium.visible_for_user?(user)) ||
      medium.free?
    end

    can :update_tags, Medium do |medium|
      !user.generic? && user.can_edit?(medium)
    end

    can [:register_download], Medium do |medium|
      !user.new_record?
    end
  end
end