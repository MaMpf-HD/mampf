class CertificationStaleCheckJob
  include Sidekiq::Worker

  LOGGED_USER_ID_SAMPLE_SIZE = 20

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
      "user_ids=#{sampled_user_ids(stale_user_ids)}"
    )
  end

  private

    def sampled_user_ids(user_ids)
      sample = user_ids.take(LOGGED_USER_ID_SAMPLE_SIZE).join(",")
      omitted = user_ids.size - LOGGED_USER_ID_SAMPLE_SIZE
      return sample unless omitted.positive?

      "#{sample} (+#{omitted} more)"
    end
end
