# https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html
class Current < ActiveSupport::CurrentAttributes
  attribute :user
  # Holds a Set of [ClassName, id] pairs that have been processed by the
  # CacheInvalidatorService in the current request. This prevents redundant
  # invalidation runs from cascading callbacks (e.g., dependent: :destroy).
  attribute :invalidation_processed
end
