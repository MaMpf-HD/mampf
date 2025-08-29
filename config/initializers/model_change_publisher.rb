ActiveSupport.on_load(:active_record) do
  # Use after_commit for create/update to ensure the transaction is complete.
  after_commit on: [:create, :update] do
    # Use `saved_change_to_id?` for precise create vs. update detection.
    action = saved_change_to_id? ? "created" : "updated"
    event_name = "model.#{self.class.name.underscore}.#{action}"
    ActiveSupport::Notifications.instrument(event_name, model: self)
  end

  # Use before_destroy to ensure associations are still present for invalidation.
  before_destroy do
    ActiveSupport::Notifications.instrument("model.#{self.class.name.underscore}.destroying",
                                            model: self)
  end

  # Use after_commit on destroy to confirm deletion for other systems (e.g., search index).
  after_commit on: :destroy do
    ActiveSupport::Notifications.instrument("model.#{self.class.name.underscore}.destroyed",
                                            model: self)
  end
end
