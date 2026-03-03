module StudentPerformance
  # Missing top-level docstring, please formulate one yourself 😁
  class CertificationsController < ApplicationController
    before_action :set_lecture
    before_action :authorize_lecture
    before_action :use_lecture_locale
    before_action :set_rule, only: :index

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
    end

    helper_method :filter_records

    private

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
        @proposal_by_user = @proposals.to_h { |rec, res| [rec.user_id, res] }
      end

      def compute_summary_counts
        @total_students = @lecture.student_performance_records.count
        @passed_count = @certifications.count(&:passed?)
        @failed_count = @certifications.count(&:failed?)
        @pending_count = @certifications.count(&:pending?)
        @stale_count = @lecture.student_performance_certifications
                               .stale.count
      end

      def filter_records(records)
        return records unless params[:status].present?

        if params[:status] == "uncertified"
          certified_user_ids = @certifications.map(&:user_id)
          return records.where.not(user_id: certified_user_ids)
        end

        certified_user_ids = @certifications
                             .select { |c| c.status.to_sym == params[:status].to_sym }
                             .map(&:user_id)
        records.where(user_id: certified_user_ids)
      end
  end
end
