module Rosters
  class UserAlreadyInBundleError < StandardError
    attr_reader :conflicting_group

    def initialize(conflicting_group)
      @conflicting_group = conflicting_group
      super
    end
  end
end