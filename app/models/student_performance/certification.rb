module StudentPerformance
  # The decision on one student's exam admission in one lecture: who made it,
  # when, and against which rule. A missing row means nobody has looked yet;
  # `pending` means someone looked and could not decide.
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

    # `pending` is what the rule writes when it cannot decide. A person
    # choosing by hand has decided; the select offers passed and failed only.
    validates :status, exclusion: { in: ["pending"],
                                    message: :manual_cannot_be_pending },
                       if: :manual?

    scope :decided, -> { where.not(status: :pending) }

    # Drops every `computed` row, `pending` included: the lecture is back to
    # what it was before the rule was first applied. `manual` rows stay. The
    # count returned is the decisions among them, because a `pending` row was
    # never one and its removal changes no screen.
    def self.reset_computed!
      dropped = computed.decided.count
      computed.delete_all
      dropped
    end

    def self.status_for_proposal(proposed_status)
      proposed_status == :inconclusive ? :pending : proposed_status
    end

    def disagrees_with?(proposed_status)
      status.to_sym != self.class.status_for_proposal(proposed_status)
    end

    # A row that was never evaluated is the most out-of-date one there is, but
    # `x > NULL` yields NULL rather than false and would drop it from every scope
    # below. The nil case is therefore spelled out.
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
          .or(cert_table[:certified_at].eq(nil))
      )
    }

    # The two scopes below name the reason and are what the overview counts.
    # They inner-join on purpose where `stale` outer-joins: a certification
    # without a rule cannot be stale *from* a rule, but it is stale.
    scope :stale_from_rule, lambda {
      rule_table = Rule.arel_table
      cert_table = arel_table

      joins(
        cert_table.join(rule_table).on(
          rule_table[:id].eq(cert_table[:rule_id])
        ).join_sources
      ).where(
        rule_table[:updated_at].gt(cert_table[:certified_at])
          .or(cert_table[:certified_at].eq(nil))
      )
    }

    # A decision taken while the lecture had no rule names none, so
    # `stale_from_rule` cannot reach it through `rule_id`. The rule it would be
    # measured against today is the lecture's active one, of which there is at
    # most one (`index_sp_rules_one_active_per_lecture`).
    scope :stale_from_first_rule, lambda {
      rule_table = Rule.arel_table
      cert_table = arel_table

      where(rule_id: nil).joins(
        cert_table.join(rule_table).on(
          rule_table[:lecture_id].eq(cert_table[:lecture_id])
            .and(rule_table[:active].eq(true))
        ).join_sources
      ).where(
        rule_table[:updated_at].gt(cert_table[:certified_at])
          .or(cert_table[:certified_at].eq(nil))
      )
    }

    # The three scopes join different tables, so they are unioned by id rather
    # than `or`ed: a manual decision for someone without a `Record` keeps its
    # rule reason that way.
    scope :stale_manual, lambda {
      where(id: manual.stale_from_rule.pluck(:id) |
                manual.stale_from_first_rule.pluck(:id) |
                manual.stale_from_data.pluck(:id))
    }

    scope :stale_from_data, lambda {
      record_table = Record.arel_table
      cert_table = arel_table

      joins(
        cert_table.join(record_table).on(
          record_table[:lecture_id].eq(cert_table[:lecture_id])
            .and(record_table[:user_id].eq(cert_table[:user_id]))
        ).join_sources
      ).where(
        record_table[:computed_at].gt(cert_table[:certified_at])
          .or(cert_table[:certified_at].eq(nil))
      )
    }
  end
end
