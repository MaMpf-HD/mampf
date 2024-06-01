# Callback documentation for Warden (used by Devise):
# https://github.com/wardencommunity/warden/wiki/Callbacks#after_authentication
Warden::Manager.after_authentication do |user, _auth, _opts|
  # See the UserCleaner class for more information
  user.deletion_date = nil

  # TODO: Add Cypress integration tests for this behavior. For now,
  # test this behavior manually, e.g on localhost:5050 via pgadmin.
end
