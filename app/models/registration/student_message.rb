module Registration
  # The name a delivery job enqueued before the rename carries in its
  # GlobalID; it deserializes to the record under its new name. Needed
  # until every job under the old name, retries included, has run.
  StudentMessage = ::StudentMessage
end
