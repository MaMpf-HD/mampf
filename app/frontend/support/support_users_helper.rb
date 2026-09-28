module SupportUsersHelper
  # Lists a person the way exam lists do: last name first.
  def listed_name(user)
    [user.last_name, user.first_name].compact.join(", ").presence || user.name
  end
end
