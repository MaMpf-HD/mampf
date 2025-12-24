require "json"
require "base64"

module Search
  module Pagination
    # A simple keyset pagination implementation.
    class KeysetPager
      # Paginates the given ActiveRecord relation using keyset pagination.
      #
      # @param set [ActiveRecord::Relation] The ActiveRecord relation to paginate.
      # @param keyset [Hash{Symbol => Symbol}] The keyset mapping alias names to directions.
      # @param limit [Integer] The maximum number of records to return.
      # @param page [String, nil] The encoded cursor for the current page.
      # @return [Array<Page, ActiveRecord::Relation>] A tuple containing the Page
      #  object and the records.
      def self.paginate(set:, keyset:, limit:, page: nil)
        prior_cutoff = decode(page) if page && page != ""
        set = apply_where(set, keyset, prior_cutoff) if prior_cutoff

        records = set.limit(limit + 1).to_a
        more = records.size > limit
        records = records.first(limit)

        next_cursor = more ? encode(extract_cutoff(records.last, keyset)) : nil
        [Page.new(next_cursor), records]
      end

      class Page
        attr_reader :next

        def initialize(next_cursor)
          @next = next_cursor
        end
      end

      class << self
        private

          def encode(values)
            Base64.urlsafe_encode64(JSON.generate(values))
          end

          def decode(str)
            JSON.parse(Base64.urlsafe_decode64(str))
          end

          def extract_cutoff(record, keyset)
            keyset.keys.map { |k| record[k] }
          end

          # Applies the keyset WHERE clause to the ActiveRecord relation.
          #
          # @param set [ActiveRecord::Relation] The ActiveRecord relation.
          # @param keyset [Hash{Symbol => Symbol}] The keyset mapping alias names to directions.
          # @param cutoff [Array] The cutoff values for the keyset.
          # @return [ActiveRecord::Relation] The modified relation with the WHERE clause applied.
          def apply_where(set, keyset, cutoff)
            operator = { asc: ">", desc: "<" }
            placeholders = keyset.keys.zip(cutoff).to_h

            ks = keyset.to_a
            unions = []
            until ks.empty?
              last_key, last_dir = ks.pop
              parts = ks.map { |k, _| "#{k} = :#{k}" }
              parts << "#{last_key} #{operator[last_dir]} :#{last_key}"
              unions << "(#{parts.join(" AND ")})"
            end
            predicate = unions.join(" OR ")
            set.where(predicate, **placeholders)
          end
      end
    end
  end
end
