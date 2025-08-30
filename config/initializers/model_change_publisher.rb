ActiveSupport.on_load(:active_record) do
  # Track nested destroy depth per-thread to detect the "root" of a cascade.
  around_destroy do |_record, block|
    Thread.current[:_destroy_depth] = Thread.current[:_destroy_depth].to_i + 1
    begin
      block.call
    ensure
      Thread.current[:_destroy_depth] = Thread.current[:_destroy_depth].to_i - 1
    end
  end

  # Fire our special invalidation event once, at the start of the outermost
  # destroy, while all associations are still intact.
  before_destroy do
    if Thread.current[:_destroy_depth].to_i == 1
      ActiveSupport::Notifications.instrument(
        "model.#{self.class.name.underscore}.destroying_root",
        model: self
      )
    end
  end

  # Use after_commit for create/update to ensure the transaction is complete.
  after_commit on: [:create, :update] do
    action = transaction_include_any_action?([:create]) ? "created" : "updated"
    ActiveSupport::Notifications.instrument(
      "model.#{self.class.name.underscore}.#{action}",
      model: self
    )
  end

  # This is a generic "destroyed" event that other systems might use.
  # Our cache invalidator will not listen to this one.
  after_commit on: :destroy do
    ActiveSupport::Notifications.instrument(
      "model.#{self.class.name.underscore}.destroyed",
      model: self
    )
  end
end
