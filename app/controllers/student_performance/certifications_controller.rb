module StudentPerformance
  class CertificationsController < ApplicationController
    include StudentPerformance::LectureScoped

    before_action :set_rule, only: [:index, :create, :bulk_accept,
                                    :bulk_reevaluate]
    before_action :set_certification, only: [:update, :destroy]

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, alert: exception.message
    end

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def index
      # A link saved under the filter's old name would land on an empty table.
      if params[:status] == "stale"
        redirect_to lecture_student_performance_certifications_path(
          @lecture, status: "flagged"
        )
        return
      end

      @due_points = due_points
      load_certifications
      load_proposals if @rule
      @proposal_by_user ||= {}
      compute_summary_counts
      compute_proposal_counts if @rule
      flag_certifications
      @achievements = if @rule
        @rule.required_achievements.order(:title)
      else
        Achievement.none
      end
      load_filtered_records
    end

    def create
      record = @lecture.student_performance_records
                       .find_by(user_id: certification_params[:user_id])
      unless record
        redirect_to lecture_student_performance_certifications_path(@lecture),
                    alert: I18n.t("student_performance.errors.no_member")
        return
      end

      cert = @lecture.student_performance_certifications
                     .find_or_initialize_by(user: record.user)

      if cert.persisted? && cert.manual?
        redirect_to lecture_student_performance_certifications_path(@lecture),
                    alert: I18n.t(
                      "student_performance.certifications.flash.manual_exists"
                    )
        return
      end

      cert.assign_attributes(
        status: certification_params[:status],
        source: :manual,
        certified_by: current_user,
        certified_at: Time.current,
        rule: @rule
      )

      if cert.save
        redirect_to return_to_path,
                    notice: I18n.t("student_performance.certifications.flash.created")
      else
        redirect_to return_to_path,
                    alert: cert.errors.full_messages.first
      end
    end

    def bulk_accept
      unless @rule
        redirect_to lecture_student_performance_certifications_path(@lecture),
                    alert: I18n.t("student_performance.evaluator.no_rule")
        return
      end

      # When assignments_complete? is false, every proposal is inconclusive;
      # bulk_accept would only create or update pending certifications.
      unless @lecture.assignments_complete?
        redirect_to lecture_student_performance_certifications_path(@lecture),
                    alert: I18n.t(
                      "student_performance.certifications.index.assignments_incomplete",
                      tab: I18n.t("assessment.tabs.assignments")
                    )
        return
      end

      records = @lecture.student_performance_records
                        .includes(:user)
      evaluator = evaluator_for(@rule)
      proposals = evaluator.bulk_evaluate(records)

      existing_certs = @lecture.student_performance_certifications
                               .index_by(&:user_id)
      created = 0
      inconclusive = 0

      ActiveRecord::Base.transaction do
        proposals.each do |record, result|
          cert = existing_certs[record.user_id] ||
                 @lecture.student_performance_certifications
                         .build(user_id: record.user_id)

          if cert.persisted? &&
             (cert.manual? ||
              (!cert.pending? &&
               cert.disagrees_with?(result.proposed_status)))
            next
          end

          cert.assign_attributes(
            attributes_for_proposal(result.proposed_status)
          )
          cert.save!
          if result.proposed_status == :inconclusive
            inconclusive += 1
          else
            created += 1
          end
        end
      end

      redirect_to lecture_student_performance_certifications_path(@lecture),
                  notice: bulk_accept_notice(created, inconclusive)
    end

    def bulk_reevaluate
      unless @rule
        redirect_to lecture_student_performance_certifications_path(@lecture),
                    alert: I18n.t("student_performance.evaluator.no_rule")
        return
      end

      # A computed decision is compared with today's proposal rather than with
      # a timestamp, and rewritten only where the two differ. `pending` rows
      # carry no decision; `bulk_accept` writes those.
      computed_certs = @lecture.student_performance_certifications
                               .computed.decided
      evaluator = evaluator_for(@rule)
      records_by_user = @lecture.student_performance_records.index_by(&:user_id)
      updated = 0
      reset_to_pending = 0

      ActiveRecord::Base.transaction do
        computed_certs.find_each do |cert|
          record = records_by_user[cert.user_id]
          next unless record

          result = evaluator.evaluate(record)
          next unless cert.disagrees_with?(result.proposed_status)

          cert.update!(attributes_for_proposal(result.proposed_status))
          if result.proposed_status == :inconclusive
            reset_to_pending += 1
          else
            updated += 1
          end
        end
      end

      redirect_to lecture_student_performance_certifications_path(@lecture),
                  notice: reevaluated_notice(updated, reset_to_pending)
    end

    def bulk_confirm_manual
      # rubocop:disable Rails/SkipsModelValidations
      confirmed = @lecture.student_performance_certifications
                          .stale_manual
                          .update_all(certified_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations

      redirect_to lecture_student_performance_certifications_path(@lecture),
                  notice: I18n.t(
                    "student_performance.certifications.flash.confirmed",
                    count: confirmed
                  )
    end

    def bulk_reset
      count = @lecture.student_performance_certifications.reset_computed!

      redirect_to lecture_student_performance_certifications_path(@lecture),
                  notice: I18n.t("student_performance.certifications.flash.reset",
                                 count: count)
    end

    def update
      cert = @certification
      cert.assign_attributes(
        status: update_certification_params[:status],
        note: update_certification_params[:note],
        source: :manual,
        certified_by: current_user,
        certified_at: Time.current
      )

      if cert.save
        redirect_to return_to_path,
                    notice: I18n.t("student_performance.certifications.flash.updated")
      else
        redirect_to return_to_path,
                    alert: cert.errors.full_messages.first
      end
    end

    # Deleting the row puts the student back to "no decision":
    # Registration::Policy::StudentPerformanceHandler counts a missing row as
    # outstanding, so no reset can admit anybody.
    def destroy
      @certification.destroy!

      redirect_to return_to_path,
                  notice: I18n.t("student_performance.certifications.flash.reset_one")
    end

    private

      def return_to_path
        if params[:return_to].present?
          begin
            uri = URI.parse(params[:return_to])
            return params[:return_to] if uri.host.nil? || uri.host == request.host
          rescue URI::InvalidURIError
            # fall through
          end
        end
        lecture_student_performance_certifications_path(@lecture)
      end

      def set_certification
        @certification = @lecture.student_performance_certifications
                                 .find(params[:id])
      end

      def set_rule
        @rule = StudentPerformance::Rule
                .where(lecture: @lecture, active: true)
                .includes(rule_achievements: :achievement)
                .first
      end

      def load_certifications
        @certifications = @lecture.student_performance_certifications
                                  .includes(:user, :certified_by)
                                  .order(:created_at)
        @cert_by_user = @certifications.index_by(&:user_id)
      end

      def load_proposals
        records = @lecture.student_performance_records
                          .includes(:user)
                          .order(:created_at)

        evaluator = evaluator_for(@rule)
        @proposals = evaluator.bulk_evaluate(records)
        @proposal_by_user = @proposals.transform_keys(&:user_id)
      end

      def compute_summary_counts
        @total_students = @lecture.student_performance_records.count
        @passed_count = @certifications.count(&:passed?)
        @failed_count = @certifications.count(&:failed?)
        @computed_count = @certifications.count { |c| c.computed? && !c.pending? }
        decided_count = @passed_count + @failed_count
        @uncertified_count = @total_students - decided_count
      end

      # One reason per source: a `computed` row the rule would decide
      # differently today, a `manual` row whose rule or record changed after it
      # was made. A `pending` row is no decision, so nothing can contradict it.
      def flag_certifications
        @disagreeing_user_ids = @certifications.select do |cert|
          proposal = @proposal_by_user[cert.user_id]
          cert.computed? && !cert.pending? && proposal &&
            cert.disagrees_with?(proposal.proposed_status)
        end.to_set(&:user_id)
        @stale_manual_user_ids = @lecture.student_performance_certifications
                                         .stale_manual.pluck(:user_id).to_set
        @flagged_user_ids = @disagreeing_user_ids | @stale_manual_user_ids
      end

      def compute_proposal_counts
        decided_user_ids = @certifications.reject(&:pending?)
                                          .to_set(&:user_id)
        uncertified_proposals = @proposal_by_user.except(*decided_user_ids)
        @proposed_passed = uncertified_proposals.count { |_, r| r.proposed_status == :passed }
        @proposed_failed = uncertified_proposals.count { |_, r| r.proposed_status == :failed }
        @proposed_inconclusive = uncertified_proposals.count do |_, r|
          r.proposed_status == :inconclusive
        end
      end

      # By id after the timestamp, because the records of a lecture are written
      # in one go and carry the same one: a page cut with OFFSET would then
      # show a student twice and skip another. Measured, not feared.
      def load_filtered_records
        records = @lecture.student_performance_records
                          .includes(:user)
                          .order(:created_at, :id)
        @pagy, @filtered_records = pagy(filter_records(filter_by_name(records)))
      end

      def filter_records(records)
        return records if params[:status].blank?

        if params[:status] == "uncertified"
          decided_user_ids = @certifications.reject(&:pending?).map(&:user_id)
          return records.where.not(user_id: decided_user_ids)
        end

        return records.where(user_id: @flagged_user_ids.to_a) if params[:status] == "flagged"

        certified_user_ids = @certifications
                             .select { |c| c.status.to_sym == params[:status].to_sym }
                             .map(&:user_id)
        records.where(user_id: certified_user_ids)
      end

      def certification_params
        params.expect(certification: [:user_id, :status])
      end

      def update_certification_params
        params.expect(certification: [:status, :note])
      end

      def attributes_for_proposal(proposed_status)
        status = Certification.status_for_proposal(proposed_status)

        {
          status: status,
          source: :computed,
          certified_by: status == :pending ? nil : current_user,
          certified_at: Time.current,
          rule: @rule
        }
      end

      def bulk_accept_notice(created, inconclusive)
        counted_notice(
          { bulk_accepted: created, bulk_inconclusive: inconclusive },
          empty: :bulk_accepted
        )
      end

      def reevaluated_notice(updated, reset_to_pending)
        counted_notice(
          { reevaluated: updated, reevaluated_inconclusive: reset_to_pending },
          empty: :reevaluated_nothing
        )
      end

      def counted_notice(counts, empty:)
        parts = counts.filter_map do |key, count|
          next unless count.positive?

          I18n.t("student_performance.certifications.flash.#{key}", count: count)
        end
        return parts.join(" ") if parts.any?

        I18n.t("student_performance.certifications.flash.#{empty}", count: 0)
      end
  end
end
