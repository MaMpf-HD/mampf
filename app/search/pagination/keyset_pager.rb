require "json"
require "base64"

module Search
  module Pagination
    class KeysetPager
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

      def self.encode(values)
        Base64.urlsafe_encode64(JSON.generate(values))
      end

      def self.decode(str)
        JSON.parse(Base64.urlsafe_decode64(str))
      end

      def self.extract_cutoff(record, keyset)
        keyset.keys.map { |k| record[k] }
      end

      def self.apply_where(set, keyset, cutoff)
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
