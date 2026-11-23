# Lets a spec check the order in which a block locks rows, by model rather
# than by reading SQL: `locked_models { … }` returns the class of every
# relation loaded with a lock, lock! and with_lock included.
module LockedModels
  def locked_models
    models = []
    ActiveSupport::IsolatedExecutionState[:locked_models] = models
    yield
    models
  ensure
    ActiveSupport::IsolatedExecutionState[:locked_models] = nil
  end

  module Recorder
    private

      def exec_queries(...)
        ActiveSupport::IsolatedExecutionState[:locked_models]&.push(klass) if lock_value
        super
      end
  end
end

ActiveRecord::Relation.prepend(LockedModels::Recorder)

RSpec.configure do |config|
  config.include(LockedModels)
end
