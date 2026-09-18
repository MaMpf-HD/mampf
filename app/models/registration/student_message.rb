module Registration
  # The name a delivery job enqueued before the rename carries in its
  # GlobalID; it deserializes to the record under its new name. Drop once
  # no such job can be queued any more.
  StudentMessage = ::StudentMessage
end
