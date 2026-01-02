module Registration
  # Enables domain models (like Tutorial or Talk) to be the target of a registration campaign.
  # Enforces an interface for managing capacity and materializing the final list of
  # allocated users into the domain.
  module Registerable
    extend ActiveSupport::Concern

    # Models including this concern must:
    # - Have a `capacity` integer column (nullable: nil = infinite capacity)
    # - Implement #allocated_user_ids (returns array of user IDs)
    # - Implement #materialize_allocation!(user_ids:, campaign:)

    def allocated_user_ids
      raise(NotImplementedError, "Registerable must implement #allocated_user_ids")
    end

    def materialize_allocation!(user_ids:, campaign:)
      raise(NotImplementedError, "Registerable must implement #materialize_allocation!")
    end
  end
end
