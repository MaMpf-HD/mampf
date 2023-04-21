class ErdbeereAbility
  include CanCan::Ability

  def initialize(user)
    clear_aliased_actions

    can [:show_example, :show_property, :show_structure,
         :find_tags, :display_info, :find_example], :erdbeere

    can [:edit_tags, :cancel_edit_tags, :update_tags,
         :fill_realizations_select], :erdbeere do
      !user.generic?
    end
  end
end