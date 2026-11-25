class CommandPaletteController < ApplicationController
  def current_ability
    @current_ability ||= CommandPaletteAbility.new(current_user)
  end

  # all published lectures
  def catalog
    authorize! :catalog, :command_palette
    render json: CommandPaletteCatalog.entries
  end

  # the user's own data
  def me
    authorize! :me, :command_palette
    render json: CommandPaletteUserData.new(current_user).as_json
  end
end
