# This is the abstract base class for all search configurators.
#
# It establishes a common interface and structure for defining which search
# filters and parameters should be applied for a given model (e.g., Media,
# Lectures).
#
# Subclasses are responsible for implementing the `call` method, which should
# return a `Configuration` struct containing an array of filter classes and the
# processed search parameters.
module Search
  module Configurators
    class BaseSearchConfigurator
      # This struct provides a consistent return object for all configurators.
      Configuration = Struct.new(:filters, :params, :orderer_class, keyword_init: true)

      # Entry point for the service.
      #
      # @param user [User] The current user.
      # @param search_params [Hash] The search parameters.
      # @return [Configuration] An object containing the filter classes and params.
      def self.call(user:, search_params:)
        new(user: user, search_params: search_params).call
      end

      attr_reader :user, :search_params

      def initialize(user:, search_params:)
        @user = user
        @search_params = search_params.to_h.with_indifferent_access
      end

      # Subclasses should implement this method to return a Configuration struct.
      def call
        raise(NotImplementedError, "#{self.class} has not implemented method '#{__method__}'")
      end
    end
  end
end
