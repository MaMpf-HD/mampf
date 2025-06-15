# from here: https://github.com/heartcombo/devise/pull/5728#issuecomment-2539418211

# Starting from Rails 8.0, routes are lazy-loaded by default in test and
# development environments. However, Devise's mappings are built during the
# routes loading phase. To ensure it works correctly, we need to load the
# routes first before accessing @@mappings.

require "devise"
Devise.inspect

module Devise
  def self.mappings
    Rails.application.try(:reload_routes_unless_loaded)
    @@mappings
  end
end
