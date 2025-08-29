Rails.application.reloader.to_prepare do
  # Unsubscribe the old listener before subscribing a new one to prevent
  # duplicate subscriptions during development code reloads.
  if defined?(@cache_invalidator_subscription) && @cache_invalidator_subscription
    ActiveSupport::Notifications.unsubscribe(@cache_invalidator_subscription)
  end

  # Subscribe to the events that should trigger a cache cascade.
  # We listen for create, update, and the pre-destroy `destroying` event,
  # as this is when associations are guaranteed to still exist.
  event_pattern = /model\..*\.(created|updated|destroying)/

  @cache_invalidator_subscription =
    ActiveSupport::Notifications.subscribe(event_pattern) do |name, _start, _finish, _id, payload|
      model = payload[:model]
      # The service might not be loaded yet during initialization, so we check.
      CacheInvalidatorService.run(model, event_name: name) if defined?(CacheInvalidatorService)
    end
end
