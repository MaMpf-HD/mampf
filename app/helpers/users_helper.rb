# Users Helper
module UsersHelper
  def users_for_select(users)
    [['auswählen', '']] + users.map { |u| [u.info, u.id] }
  end
end
