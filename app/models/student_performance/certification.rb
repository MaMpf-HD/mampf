module StudentPerformance
  class Certification < ApplicationRecord
    enum :status, { pending: 0, passed: 1, failed: 2 }
    enum :source, { computed: 0, manual: 1 }

    belongs_to :lecture
    belongs_to :user
    belongs_to :certified_by, class_name: "User", optional: true
    belongs_to :rule, class_name: "StudentPerformance::Rule", optional: true

    validates :lecture_id, uniqueness: { scope: :user_id }
    validates :certified_by, presence: true, unless: :pending?
    validates :certified_at, presence: true, unless: :pending?

    scope :stale, lambda {
      record_table = Record.arel_table
      rule_table = Rule.arel_table
      cert_table = arel_table

      joins(
        cert_table.join(record_table).on(
          record_table[:lecture_id].eq(cert_table[:lecture_id])
            .and(record_table[:user_id].eq(cert_table[:user_id]))
        ).join_sources
      ).joins(
        cert_table.join(rule_table, Arel::Nodes::OuterJoin).on(
          rule_table[:id].eq(cert_table[:rule_id])
        ).join_sources
      ).where(
        record_table[:computed_at].gt(cert_table[:certified_at])
          .or(rule_table[:updated_at].gt(cert_table[:certified_at]))
      )
    }

    scope :stale_from_rule, lambda {
      rule_table = Rule.arel_table
      cert_table = arel_table

      joins(
        cert_table.join(rule_table).on(
          rule_table[:id].eq(cert_table[:rule_id])
        ).join_sources
      ).where(rule_table[:updated_at].gt(cert_table[:certified_at]))
    }

    scope :stale_from_data, lambda {
      record_table = Record.arel_table
      cert_table = arel_table

      joins(
        cert_table.join(record_table).on(
          record_table[:lecture_id].eq(cert_table[:lecture_id])
            .and(record_table[:user_id].eq(cert_table[:user_id]))
        ).join_sources
      ).where(record_table[:computed_at].gt(cert_table[:certified_at]))
    }

    def self.passed?(lecture:, user:)
      find_by(lecture: lecture, user: user)&.passed? || false
    end
  end
end
