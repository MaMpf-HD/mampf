module Registration
  module Registerable
    extend ActiveSupport::Concern

    def capacity
      raise(NotImplementedError, "Registerable must implement #capacity")
    end

    def allocated_user_ids
      raise(NotImplementedError, "Registerable must implement #allocated_user_ids")
    end

    def materialize_allocation!(user_ids:, campaign:)
      raise(NotImplementedError, "Registerable must implement #materialize_allocation!")
    end
  end
end
