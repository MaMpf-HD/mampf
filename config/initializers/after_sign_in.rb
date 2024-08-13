# Callback documentation for Warden (used by Devise):
# https://github.com/wardencommunity/warden/wiki/Callbacks#after_authentication
Warden::Manager.after_authentication do |user, _auth, _opts|
  # User might have not logged in for a long time, which is why they have a
  # deletion date set. If the user logs in, we unset this date to prevent the
  # user from being deleted. See the UserCleaner class for more information.
  # In case this callback does not work, a safety net is provided by the method
  # `unset_deletion_date_for_recently_active_users` in the UserCleaner class.
  user.deletion_date = nil
end
