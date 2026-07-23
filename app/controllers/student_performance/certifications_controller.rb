module StudentPerformance
  class CertificationsController < ApplicationController
    before_action :set_lecture
    before_action :authorize_lecture
    before_action :use_lecture_locale
    before_action :set_rule, only: [:index, :create, :bulk_accept,
                                    :bulk_reevaluate]

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, alert: exception.message
    end

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def index
      load_certifications
      load_proposals if @rule
      @proposal_by_user ||= {}
      compute_summary_counts
      compute_proposal_counts if @rule
      @stale_user_ids = @lecture.student_performance_certifications
                                .stale.pluck(:user_id).to_set
      stale_from_rule = @lecture.student_performance_certifications
                                .stale_from_rule
      @stale_from_rule_auto_count = stale_from_rule
                                    .where.not(source: :manual).count
      @stale_from_rule_manual_count = stale_from_rule
                                      .where(source: :manual).count
      stale_from_data = @lecture.student_performance_certifications
                                .stale_from_data
      @stale_from_data_auto_count = stale_from_data
                                    .where.not(source: :manual).count
      @stale_from_data_manual_count = stale_from_data
                                      .where(source: :manual).count
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

      records = @lecture.student_performance_records
                        .includes(:user)
      evaluator = StudentPerformance::Evaluator.new(@rule)
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
               cert.status.to_sym != result.proposed_status))
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

      stale_certs = @lecture.student_performance_certifications
                            .stale.where.not(source: :manual)
                            .includes(:user)
      evaluator = StudentPerformance::Evaluator.new(@rule)
      updated = 0
      reset_to_pending = 0

      ActiveRecord::Base.transaction do
        stale_certs.find_each do |cert|
          record = @lecture.student_performance_records
                           .find_by(user: cert.user)
          next unless record

          result = evaluator.evaluate(record)
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
                          .stale.where(source: :manual)
                          .update_all(certified_at: Time.current)
      # rubocop:enable Rails/SkipsModelValidations

      redirect_to lecture_student_performance_certifications_path(@lecture),
                  notice: I18n.t(
                    "student_performance.certifications.flash.confirmed",
                    count: confirmed
                  )
    end

    def update
      cert = @lecture.student_performance_certifications
                     .find(params[:id])
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

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        redirect_to root_path,
                    alert: I18n.t("student_performance.errors.no_lecture")
      end

      def authorize_lecture
        authorize!(:edit, @lecture)
      end

      def use_lecture_locale
        locale = @lecture&.locale_with_inheritance || I18n.default_locale
        I18n.locale = locale
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

        evaluator = StudentPerformance::Evaluator.new(@rule)
        @proposals = evaluator.bulk_evaluate(records)
        @proposal_by_user = @proposals.transform_keys(&:user_id)
      end

      def compute_summary_counts
        @total_students = @lecture.student_performance_records.count
        @passed_count = @certifications.count(&:passed?)
        @failed_count = @certifications.count(&:failed?)
        decided_count = @passed_count + @failed_count
        @uncertified_count = @total_students - decided_count
        @stale_count = @lecture.student_performance_certifications
                               .stale.count
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

      def load_filtered_records
        records = @lecture.student_performance_records
                          .includes(:user)
                          .order(:created_at)
        @filtered_records = filter_records(records)
      end

      def filter_records(records)
        return records if params[:status].blank?

        if params[:status] == "uncertified"
          decided_user_ids = @certifications.reject(&:pending?).map(&:user_id)
          return records.where.not(user_id: decided_user_ids)
        end

        return records.where(user_id: @stale_user_ids.to_a) if params[:status] == "stale"

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
        if proposed_status == :inconclusive
          {
            status: :pending,
            source: :computed,
            certified_by: nil,
            certified_at: Time.current,
            rule: @rule
          }
        else
          {
            status: proposed_status,
            source: :computed,
            certified_by: current_user,
            certified_at: Time.current,
            rule: @rule
          }
        end
      end

      def bulk_accept_notice(created, inconclusive)
        parts = [
          I18n.t("student_performance.certifications.flash.bulk_accepted",
                 count: created)
        ]
        if inconclusive.positive?
          parts << I18n.t(
            "student_performance.certifications.flash.bulk_inconclusive",
            count: inconclusive
          )
        end
        parts.join(" ")
      end

      def reevaluated_notice(updated, reset_to_pending)
        parts = [
          I18n.t("student_performance.certifications.flash.reevaluated",
                 count: updated)
        ]
        if reset_to_pending.positive?
          parts << I18n.t(
            "student_performance.certifications.flash.reevaluated_inconclusive",
            count: reset_to_pending
          )
        end
        parts.join(" ")
      end
  end
end
