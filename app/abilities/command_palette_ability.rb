class CommandPaletteAbility
  include CanCan::Ability

  def initialize(_user)
    can [:catalog, :me], :command_palette
  end
end
