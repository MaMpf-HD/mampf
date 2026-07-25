class CertificationStaleCheckJob
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 1

  def perform(lecture_id)
    stale_user_ids = StudentPerformance::Certification
                     .where(lecture_id: lecture_id)
                     .stale
                     .distinct
                     .pluck(:user_id)

    return if stale_user_ids.empty?

    Rails.logger.info(
      "[CertificationStaleCheck] lecture_id=#{lecture_id} " \
      "stale_count=#{stale_user_ids.size} " \
      "user_ids=#{stale_user_ids.join(",")}"
    )
  end
end
