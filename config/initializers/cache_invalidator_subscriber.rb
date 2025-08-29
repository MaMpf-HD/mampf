# This module ensures that the ActiveSupport::Notifications subscription for the
# cache invalidator is only created once, even during code reloads in development.
module CacheInvalidatorSubscriptionHandler
  # mattr_accessor creates a class-level variable that persists across reloads.
  mattr_accessor :subscription, default: nil

  # This method is idempotent. It will only subscribe if no subscription exists.
  def self.subscribe!
    # Do nothing if we already have a subscription object.
    return if subscription

    # The pattern of model events we want to listen for.
    event_pattern = /model\..*\.(created|updated|destroying)/

    # Subscribe and store the subscription object in our persistent class variable.
    self.subscription =
      ActiveSupport::Notifications.subscribe(event_pattern) do |_name, _start,
        _finish, _id, payload|
        model = payload[:model]
        # The service might not be loaded yet during initialization, so we check.
        CacheInvalidatorService.run(model) if defined?(CacheInvalidatorService)
      end

    # This should only appear once per server boot, confirming idempotency.
    Rails.logger.info("=> Cache invalidator subscribed with object_id: #{subscription.object_id}")
  end
end

# The to_prepare block runs before every request in development and once in production.
# Calling our idempotent subscribe! method here ensures that the subscription is
# always active without creating duplicates.
Rails.application.reloader.to_prepare do
  CacheInvalidatorSubscriptionHandler.subscribe!
end
